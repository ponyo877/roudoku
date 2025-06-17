import '../../domain/usecases/get_books_usecase.dart';
import '../../domain/entities/book_entity.dart';
import '../../../../core/providers/base_provider.dart';
import '../../../../core/state/base_state.dart';
import '../../../../core/logging/logger.dart';

class BooksProvider extends ListProvider<BookEntity> {
  final GetBooksUseCase _getBooksUseCase;
  final GetRecommendationsUseCase _getRecommendationsUseCase;
  final SearchBooksUseCase _searchBooksUseCase;

  BooksProvider({
    required GetBooksUseCase getBooksUseCase,
    required GetRecommendationsUseCase getRecommendationsUseCase,
    required SearchBooksUseCase searchBooksUseCase,
  })  : _getBooksUseCase = getBooksUseCase,
        _getRecommendationsUseCase = getRecommendationsUseCase,
        _searchBooksUseCase = searchBooksUseCase;

  @override
  Future<ListResult<BookEntity>> fetchData({required int page}) async {
    Logger.book('Fetching books for page: $page');
    final books = await _getBooksUseCase.execute();
    
    // Simulate pagination for demo purposes
    const pageSize = 20;
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, books.length);
    
    if (startIndex >= books.length) {
      return ListResult(items: [], hasMore: false, page: page);
    }
    
    final pageItems = books.sublist(startIndex, endIndex);
    final hasMore = endIndex < books.length;
    
    return ListResult(
      items: pageItems,
      hasMore: hasMore,
      page: page,
    );
  }

  Future<void> loadRecommendations() async {
    Logger.book('Loading book recommendations');
    await executeAsync(
      () => _getRecommendationsUseCase.execute(),
      onSuccess: (books) => ListState<BookEntity>.success(books),
    );
  }

  Future<void> searchBooks({String? query, String? genre}) async {
    Logger.book('Searching books with query: $query, genre: $genre');
    await executeAsync(
      () => _searchBooksUseCase.execute(query: query, genre: genre),
      onSuccess: (books) => ListState<BookEntity>.success(books),
    );
  }

  void clearSearch() {
    Logger.book('Clearing book search');
    updateState(ListState<BookEntity>.initial());
  }
}

class BookDetailProvider extends BaseProvider<BookEntity> {
  final GetBookByIdUseCase _getBookByIdUseCase;

  BookDetailProvider({
    required GetBookByIdUseCase getBookByIdUseCase,
  })  : _getBookByIdUseCase = getBookByIdUseCase,
        super(DataState<BookEntity>.initial());

  Future<void> loadBook(String bookId) async {
    Logger.book('Loading book detail: $bookId');
    await executeAsync(
      () async {
        final book = await _getBookByIdUseCase.execute(bookId);
        if (book == null) {
          throw Exception('Book not found');
        }
        return book;
      },
      onSuccess: (book) => DataState<BookEntity>.success(book),
    );
  }

  void clearBook() {
    Logger.book('Clearing book detail');
    updateState(DataState<BookEntity>.initial());
  }
}