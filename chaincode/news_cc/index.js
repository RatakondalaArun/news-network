const { Contract, Context } = require("fabric-contract-api");

class NewsContract extends Contract {
  constructor() {
    super("NewsContract");
  }

  async initLedger(cxt) {
    console.info("Chaincode initilized", cxt);
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
