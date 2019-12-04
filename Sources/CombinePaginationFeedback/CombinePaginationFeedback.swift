import Combine
import CombineFeedback

public typealias PageProvider<PageDependency, Element> = (PageDependency) -> AnyPublisher<Page<PageDependency, Element>, Error>

extension Publishers {

    /**
     Combine operator to handle pagination use cases.

     `PageDependency`: Any type of information needed to fetch a page.

     `Element`: The accumulated elements during paging.

     - parameter scheduler: The scheduler used to reduce the events.
     - parameter initialDependency: The initial dependency needed to fetch first page.
     - parameter loadNext: Observable of load next events.
     - parameter pageProvider: Provides observable of page given a `PageDependency`.
     - returns: The pagination state.
     */

    public static func paginationSystem<PageDependency, Element, S: Scheduler>(
        scheduler: S,
        initialDependency: PageDependency,
        loadNext: AnyPublisher<Void, Never>,
        pageProvider: @escaping PageProvider<PageDependency, Element>
    ) -> AnyPublisher<PaginationState<PageDependency, Element>, Never> {
        return system(
            initial: .init(nextDependency: initialDependency),
            feedbacks: [
                Feedback(
                    lensing: { $0.loadNextPage },
                    effects: {
                        pageProvider($0)
                            .map { .page(.success($0)) }
                            .catch { Just(.page(.failure($0))) }
                    }
                ),
                Feedback {
                    $0.flatMapLatest {
                        $0.isLoading ? Empty().eraseToAnyPublisher() : loadNext
                    }
                    .map { .loadNext }
                }
            ],
            scheduler: scheduler,
            reduce: PaginationState.reduce
        )
    }
}
