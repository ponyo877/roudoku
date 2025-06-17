import '../repositories/book_repository_interface.dart';
import '../entities/book_entity.dart';
import '../../../../core/logging/logger.dart';

class GetBooksUseCase {
  final BookRepositoryInterface _repository;

  GetBooksUseCase({required BookRepositoryInterface repository})
      : _repository = repository;

  Future<List<BookEntity>> execute() async {
    Logger.book('Executing get books use case');
    return await _repository.getAllBooks();
  }
}

class GetRecommendationsUseCase {
  final BookRepositoryInterface _repository;

  GetRecommendationsUseCase({required BookRepositoryInterface repository})
      : _repository = repository;

  Future<List<BookEntity>> execute() async {
    Logger.book('Executing get recommendations use case');
    return await _repository.getRecommendations();
  }
}

class SearchBooksUseCase {
  final BookRepositoryInterface _repository;

  SearchBooksUseCase({required BookRepositoryInterface repository})
      : _repository = repository;

  Future<List<BookEntity>> execute({String? query, String? genre}) async {
    Logger.book('Executing search books use case: query=$query, genre=$genre');
    
    if ((query?.isEmpty ?? true) && (genre?.isEmpty ?? true)) {
      throw ArgumentError('Either query or genre must be provided');
    }

    return await _repository.searchBooks(query: query, genre: genre);
  }
}

class GetBookByIdUseCase {
  final BookRepositoryInterface _repository;

  GetBookByIdUseCase({required BookRepositoryInterface repository})
      : _repository = repository;

  Future<BookEntity?> execute(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Book ID cannot be empty');
    }

    Logger.book('Executing get book by ID use case: $id');
    return await _repository.getBookById(id);
  }
}