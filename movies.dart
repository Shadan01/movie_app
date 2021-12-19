class Movie {
  String title, year, imdb, poster,type;

  Movie(
      {required this.title,
      required this.year,
      required this.imdb,
      required this.poster,
        required this.type,});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json["Title"],
      year: json["Year"],
      imdb: json["imdbID"],
      poster: json["Poster"],
      type: json["Type"],
    );
  }
}
