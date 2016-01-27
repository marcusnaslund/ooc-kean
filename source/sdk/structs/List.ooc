List: abstract class <T> {
	_count := 0
	count ::= this _count
	empty ::= this _count == 0
	add: abstract func (item: T)
	append: abstract func (other: This<T>)
	insert: abstract func (index: Int, item: T)
	remove: abstract func ~last -> T
	remove: abstract func ~atIndex (index: Int) -> T
	removeAt: abstract func (index: Int)
	clear: abstract func
	reverse: abstract func -> This<T>
	sort: abstract func (greaterThan: Func (T, T) -> Bool)
	copy: abstract func -> This<T>
	apply: abstract func (function: Func(T))
	modify: abstract func (function: Func(T) -> T)
	map: abstract func <S> (function: Func(T) -> S) -> This<S>
	fold: abstract func <S> (S: Class, function: Func(T, S) -> S, initial: S) -> S
	getFirstElements: abstract func (number: Int) -> This<T>
	getElements: abstract func (indices: This<Int>) -> This<T>
	getSlice: abstract func ~range (range: Range) -> This<T>
	getSlice: abstract func ~indices (start, end: Int) -> This<T>
	getSliceInto: abstract func ~range (range: Range, buffer: This<T>)
	getSliceInto: abstract func ~indices (start, end: Int, buffer: This<T>)
	iterator: abstract func -> Iterator<T>
	abstract operator [] (index: Int) -> T
	abstract operator []= (index: Int, item: T)
}
