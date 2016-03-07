# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class lyric_wikia_item(scrapy.Item):
	song = scrapy.Field()
	singer = scrapy.Field()
	lyric = scrapy.Field()
	genre = scrapy.Field()
	written_by = scrapy.Field()
	album = scrapy.Field()

	def keys(self):
		return ["song", "singer", "lyric"]

