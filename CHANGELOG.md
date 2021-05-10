## 2.3.0 - May 10, 2021

-   Update `distinct_value_connectable_stream` to `1.3.0`.
-   Update `rxdart` to `0.27.0`.

## 2.2.0 - May 1, 2021

-   Stable release for null safety.

## 2.2.0-nullsafety.2 - Feb 9, 2021
-   Add `Selector`s: `select`, `select2`, ..., `select9` and `selectMany`.
    -   Selectors can compute derived data, allowing Redux to store the minimal possible state.
    -   Selectors are efficient. A selector is not recomputed unless one of its arguments changes.
    -   When using the `select`, `select2` to `select9`, `selectMany` functions, 
        keeps track of the latest arguments in which your selector function was invoked. 
        Because selectors are pure functions, the last result can be returned 
        when the arguments match without re-invoking your selector function. 
        This can provide performance benefits, particularly with selectors that perform expensive computation. 
        This practice is known as memoization.

## 2.2.0-nullsafety.1 - Nov 30, 2020
-   Fixed: support nullable action.

## 2.2.0-nullsafety.0 - Nov 28, 2020
-   Migrate this package to null safety.
-   Sdk constraints: `>=2.12.0-0 <3.0.0` based on beta release guidelines.

## 2.1.1 - Oct 30, 2020

-   Add `RxReduxStore.dispatchMany(Stream<A>)`: Dispatch a `Stream` of actions to store.
-   Add extension method `dispatchTo` on `A` and `Stream<A>`, eg: `anAction.dispatchTo(store)`, `streamOfActions.dispatchTo(store)`.

## 2.1.0 - Aug 28, 2020

-   State stream returned from `RxReduxStore` will not replay the latest state
    (Use `RxReduxStore.state` getter instead).

## 2.0.0 - Aug 27, 2020

-   Added `Logger` which allows logging current state, action and new state.
-   Added `RxReduxStore`, first-class for Flutter UI.
-   Updated docs, example, README.
-   Updated internal refactor, optimized for performance.
-   Fixed many issues.

## 1.2.0 - Apr 25, 2020

-   Breaking change: remove `rxdart` dependency

## 1.1.0 - Dec 17, 2019
-   Update `rxdart`
-   Now support extension methods

## 1.0.1+1 - Oct 7, 2019
-   Update dependencies
-   Update example

## 1.0.1 - Aug 29, 2019
-   Update dependencies
-   Some minor changes

## 1.0.0+1 - Jun 29, 2019
-   Only change description

## 1.0.0 - Jun 18, 2019

-   Add the document, README, tests and some changes

## 0.0.9 - May 22, 2019

-   Initial version, created by Stagehand
