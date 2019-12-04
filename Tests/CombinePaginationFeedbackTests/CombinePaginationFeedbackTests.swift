import XCTest
@testable import CombinePaginationFeedback
import Combine
import Thresher

class CombinePaginationFeedbackTests: XCTestCase {

    var scheduler: TestScheduler!

    override func setUp() {
        scheduler = TestScheduler()
    }

    func testSimplePagination() {

        var states: [PaginationState<Int, Int>] = []
        let dep = PassthroughSubject<Int, Never>()
        let loadNext = PassthroughSubject<Void, Never>()

        _ = dep.flatMapLatest {
            Publishers.paginationSystem(
                scheduler: self.scheduler,
                initialDependency: $0,
                loadNext: loadNext.eraseToAnyPublisher(),
                pageProvider: SimplePageProvider(pageSize: 5).getPage
            )
        }
        .receive(on: scheduler)
        .sink {
            states.append($0)
        }

        scheduler.advance()
        dep.send(0)
        scheduler.advance()
        loadNext.send(())
        scheduler.advance()
        loadNext.send(())
        scheduler.advance()
        dep.send(0)
        scheduler.advance()

        XCTAssertEqual(
            states, [
                .init(isLoading: true, nextDependency: 0, elements: []),
                .init(isLoading: false, nextDependency: 5, elements: (1...5).map { $0 }),
                .init(isLoading: true, nextDependency: 5, elements: (1...5).map { $0 }),
                .init(isLoading: false, nextDependency: 10, elements: (1...10).map { $0 }),
                .init(isLoading: true, nextDependency: 10, elements: (1...10).map { $0 }),
                .init(isLoading: false, nextDependency: 15, elements: (1...15).map { $0 }),
                .init(isLoading: true, nextDependency: 0, elements: []),
                .init(isLoading: false, nextDependency: 5, elements: (1...5).map { $0 })
            ]
        )
    }

    func testPageError() {

        var states: [PaginationState<Int, Int>] = []
        let loadNext = PassthroughSubject<Void, Never>()

        _ = Publishers.paginationSystem(
            scheduler: self.scheduler,
            initialDependency: 0,
            loadNext: loadNext.eraseToAnyPublisher(),
            pageProvider: SimplePageProvider(pageSize: 70).getPage
        )
        .receive(on: scheduler)
        .sink {
            states.append($0)
        }

        scheduler.advance()
        loadNext.send(())
        scheduler.advance()

        XCTAssertEqual(
            states, [
                .init(isLoading: true, nextDependency: 0, elements: []),
                .init(isLoading: false, nextDependency: 70, elements: (1...70).map { $0 }),
                .init(isLoading: true, nextDependency: 70, elements: (1...70).map { $0 }),
                .init(isLoading: false, nextDependency: 70, elements: (1...70).map { $0 }, error: String.outOfBounds)
            ]
        )
    }

    func testDependencyRequestCanceled() {

        var states: [PaginationState<String, Int>] = []
        let deps = PassthroughSubject<String, Never>()

        let data = [
            "page1": (1...5).map { $0 },
            "page2": (6...10).map { $0 }
        ]

        _ = deps.flatMapLatest {
            Publishers.paginationSystem(
                scheduler: self.scheduler,
                initialDependency: $0,
                loadNext: Empty().eraseToAnyPublisher()
            ) { dependency -> AnyPublisher<Page<String, Int>, Error> in
                Just(Page(nextDependency: nil, elements: data[dependency, default: []]))
                    .mapError { _ in
                        String.outOfBounds
                    }
                    .delay(for: .seconds(2), scheduler: self.scheduler)
                    .eraseToAnyPublisher()
            }
        }
        .receive(on: scheduler)
        .sink {
            states.append($0)
        }

        scheduler.advance()
        deps.send("page1")
        scheduler.advance()
        deps.send("page2")
        scheduler.advance(by: .seconds(3))

        XCTAssertEqual(
            states, [
                .init(isLoading: true, nextDependency: "page1", elements: []),
                .init(isLoading: true, nextDependency: "page2", elements: []),
                .init(isLoading: false, nextDependency: nil, elements: (6...10).map { $0 })
            ]
        )
    }
}

extension PaginationState: Equatable where PageDependency: Equatable, Element: Equatable {
    public static func == (lhs: PaginationState<PageDependency, Element>, rhs: PaginationState<PageDependency, Element>) -> Bool {
        return lhs.isLoading == rhs.isLoading
            && lhs.nextDependency == rhs.nextDependency
            && lhs.elements == rhs.elements
            && lhs.error.debugDescription == rhs.error.debugDescription
    }
}

extension String: Error {
    static let outOfBounds = "Out of Bounds"
}

class SimplePageProvider {

    let data = (1...100).map { $0 }
    let pageSize: Int

    init(pageSize: Int) {
        self.pageSize = pageSize
    }

    func getPage(accumulatedCount: Int) -> AnyPublisher<Page<Int, Int>, Error> {
        guard accumulatedCount + pageSize < data.count else { return Fail(error: String.outOfBounds).eraseToAnyPublisher() }
        return Just(
            Page(
                nextDependency: accumulatedCount + pageSize,
                elements: Array(data[accumulatedCount..<(accumulatedCount + pageSize)])
            )
        )
        .mapError { _ in
            String.outOfBounds
        }
        .eraseToAnyPublisher()
    }
}
