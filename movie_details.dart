class MovieImdb {
  String title, year, genre, writer, director, actors, plot, rating, poster;

  MovieImdb(
      {required this.title,
      required this.year,
      required this.genre,
      required this.writer,
      required this.director,
      required this.actors,
      required this.plot,
      required this.rating,
      required this.poster});

  factory MovieImdb.fromJson(Map<String, dynamic> json) {
    return MovieImdb(
        title: json["Title"],
        year: json["Year"],
        genre: json["Genre"],
        writer: json["Writer"],
        director: json["Director"],
        actors: json["Actors"],
        plot: json["Plot"],
        rating: json["imdbRating"],
        poster: json["Poster"]);
  }

  Map<String, dynamic> toMap(String imdb) => {
        'imdb': imdb,
        'title': title,
        'year': year,
        'genre': genre,
        'writer': writer,
        'director': director,
        'actors': actors,
        'plot': plot,
        'rating': rating,
        'poster': poster
      };
}
