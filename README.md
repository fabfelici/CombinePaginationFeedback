# CombinePaginationFeedback

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

Generic Combine operator to easily interact with paginated APIs. Based on [CombineFeedback](https://github.com/sergdort/CombineFeedback).

## Design

![](Images/state_diagram.png)

```swift
public typealias PageProvider<PageDependency, Element> = (PageDependency) -> AnyPublisher<Page<PageDependency, Element>, Error>

public static func paginationSystem<PageDependency, Element, S: Scheduler>(
    scheduler: S,
    initialDependency: PageDependency,
    loadNext: AnyPublisher<Void, Never>,
    pageProvider: @escaping PageProvider<PageDependency, Element>
) -> AnyPublisher<PaginationState<PageDependency, Element>, Never>
```

## Features
* Simple state machine to represent pagination use cases.
* Reusable pagination logic. No need to duplicate state across different screens with paginated apis.
* Observe state to react to loading event, latest error and changes on the list of elements.
