class Artical {
  /**
   * @param {String} id id must not be null
   * @param {String} title title must not be null
   * @param {String} content must not be null
   * @param {Number} score must not be null
   */
  constructor({ id, title, content, score }) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.score = score;
  }

  toJson() {
    return JSON.stringify({
      id: this.id,
      title: this.title,
      content: this.content,
      score: this.score,
    });
  }

  static fromJson(json) {
    if (!json) return null;
    json = JSON.parse(json);
    return new Artical({
      id: json["id"],
      title: json["title"],
      content: json["content"],
      score: json["score"],
    });
  }
}

module.exports = { Artical };
