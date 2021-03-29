const { Contract, Context } = require("fabric-contract-api");
const { Artical } = require("./src/models/article");

class NewsContract extends Contract {
  constructor() {
    super("NewsContract");
  }

  /**
   *
   * @param {Context} context
   */
  async initLedger(context) {
    console.info("Chaincode initilized", context);
    const articals = [1, 2, 3, 4, 5].map(
      (value) =>
        new Artical({
          id: `id_${value}`,
          title: `This is Article ${value}`,
          content: `This article body ${value}`,
          score: 0,
        })
    );
    for (const article of articals) {
      try {
        await context.stub.putState(article.id, Buffer.from(article.toJson()));
      } catch (error) {
        console.error(`Error while puting article`, article);
        console.error(error);
      }
    }
  }

  /**
   *
   * @param {Context} context
   * @param {News} news
   */
  async createNews(context, news) {
    console.info(`Creating news id:${news.id}`);
    await context.stub.putState(JSON.parse(news).id.toString(), Buffer.from(news));
  }

  async viewNews(context, newsId) {}

  // async queryNews(context) {}

  async updateNews(context) {}

  async _validateNews(context) {}
}

class News {
  constructor({ id, postedBy, title, body, tags, score, timestamp, metatags }) {
    this.id = id;
    this.postedBy = postedBy;
    this.title = title;
    this.body = body;
    this.tags = tags;
    this.score = score;
    this.timestamp = timestamp;
    this.metatags = metatags;
  }
}

module.exports = { NewsContract, News };

module.exports.contracts = [NewsContract];
