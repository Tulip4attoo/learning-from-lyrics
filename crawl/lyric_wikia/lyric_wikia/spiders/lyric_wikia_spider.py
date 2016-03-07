import scrapy

from lyric_wikia.items import lyric_wikia_item

# genre: rnb, pop, rock, blues, 
class lyric_wikia(scrapy.Spider):
	name = "lyric_wikia"
	allowed_domains = ["lyrics.wikia.com/"]
	start_urls = [
		"http://lyrics.wikia.com/wiki/Category:Genre/Hip_Hop?from=B",
		"http://lyrics.wikia.com/wiki/Category:Genre/Hip_Hop?from=M",
		"http://lyrics.wikia.com/wiki/Category:Genre/Hip_Hop?from=T",
		"http://lyrics.wikia.com/wiki/Category:Genre/Hip_Hop?from=E",
		"http://lyrics.wikia.com/wiki/Category:Genre/Hip_Hop?from=P"
#		"http://lyrics.wikia.com/wiki/Al_Green"
#		"http://lyrics.wikia.com/wiki/Al_Green:Back_Up_Train"
	]


	def parse(self, response):
		singer_list = response.xpath("//td/ul/li/a/@href").extract()
		for singer in singer_list:
			if ":" not in singer:
				singer_page = response.urljoin(singer)
				yield scrapy.Request(singer_page, callback = self.parse_per_genre, dont_filter = True)



	def parse_per_genre(self, response):
#		url = unicode(response.url)
#		yield scrapy.Request(url, callback = self.parse_per_page, dont_filter = True)
		id_list = response.xpath("//h2/span/@id").extract()
		for id_number in id_list:
			year = id_number[- 7 : - 3]
			try:
				if int(year) > 2005:
					id_dumb = "//h2/span[@id = '%s']/parent::*/following-sibling::*[2]/li/b/a/@href" % str(id_number)
					href_list = response.xpath(id_dumb).extract()
					for href in href_list:
						if "redlink=1" not in href:	
							url = response.urljoin(href)
							yield scrapy.Request(url, callback = self.parse_per_page, dont_filter = True)
			except Exception:
				pass


	def parse_per_page(self, response):
		item = lyric_wikia_item()
		item["song"] = response.xpath("//div/a/b/text()").extract()[1]
		item["singer"] = response.xpath("//b/a[@title]/text()").extract()
		item["lyric"] = response.xpath("//div[@class = 'lyricbox']/text()").extract()
		yield item

#response.xpath("//b/a[@title]/text()").extract()

#response.xpath("//b/a[@href]/text()").extract()

#response.xpath("//td/ul/li/a/@href").extract()

#response.xpath("//h2/following-sibling::*/li/b/a[@href]/text()").extract()

#id_list = response.xpath("//h2/span/@id").extract()









