// lib/api/item_api.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'item.dart';

part 'item_api.g.dart';

@RestApi(baseUrl: "http://localhost:3000/")
abstract class ItemApi {
  factory ItemApi(Dio dio, {String baseUrl}) = _ItemApi;

  @GET("/items")
  Future<List<Item>> getItems();

  @POST("/items")
  Future<Item> createItem(@Body() Item item);

  @PUT("/items/{id}")
  Future<Item> updateItem(@Path("id") int id, @Body() Item item);

  @DELETE("/items/{id}")
  Future<void> deleteItem(@Path("id") int id);
}
