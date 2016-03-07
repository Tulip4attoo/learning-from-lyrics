from scrapy.spider import BaseSpider
from scrapy.selector import HtmlXPathSelector
from the_2nd_try.items import the_2nd_try_Item
from scrapy.http import Request

class MySpider(BaseSpider):
	name = "the_2nd_try"
	allowed_domains = ["code.tutsplus.com"]
	start_urls = ["http://code.tutsplus.com/"]

	def parse(self, response):
		hxs = HtmlXPathSelector(response)
		titles = hxs.select("//h1[@class='posts_post-title']/a/text()").extract()
		for title in titles:
			item = the_2nd_try_Item()
			item["title"] = title
			yield item





# <a class="posts__post-title " href="http://code.tutsplus.com/tutorials/how-to-create-a-news-reader-with-react-native-setup-and-news-item-component--cms-25935">How to Create a News Reader With React Native: Setup and News Item Component</a>