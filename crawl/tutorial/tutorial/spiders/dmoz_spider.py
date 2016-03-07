import scrapy

from tutorial.items import dmoz_item

class dmoz_spider(scrapy.Spider):
	name = "dmoz"
	allowed_domains = ["dmoz.org"]
	start_urls = [
		"http://www.dmoz.org/Computers/Programming/Languages/Python/"
	]

# parse() create link to apply parse_dir_contents
	def parse(self, response):
		for href in response.xpath("//ul[@class='directory dir-col']/li/a/@href"):
#			if "/Computers/Programming/Languages/Python" in href.extract():
#				url = response.urljoin(href.extract())
#				yield scrapy.Request(url, callback = self.parse_dir_contents)
			url = response.urljoin(href.extract())
			yield scrapy.Request(url, callback = self.parse_dir_contents)

#	def parse(self, response):
#		for href in response.css("ul.directory.dir-col > li > a::attr('href')"):
#			url = response.urljoin(href.extract())
#			yield scrapy.Request(url, callback=self.parse_dir_contents)

# url = response.urljoin(response.xpath("//ul/li/a/@href").extract()[10])

	def parse_dir_contents(self, response):
		for sel in response.xpath("//ul/li"):
			item = dmoz_item()
			item["title"] = sel.xpath("a/text()").extract()
			item['link'] = sel.xpath('a/@href').extract()
			item['desc'] = sel.xpath('text()').extract()
			yield item
