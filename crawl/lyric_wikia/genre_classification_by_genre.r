library("tm")
library("SnowballC")

library("caTools")
library("rpart")
library("rpart.plot")
library("ROCR")
library("h2o")
library("e1071")


# read data and store as raw
raw_pop = read.csv("pop.csv")
raw_rock = read.csv("rock.csv")
raw_rnb = read.csv("rnb.csv")
raw_hip_hop = read.csv("hip_hop.csv")
raw_blues = read.csv("blues.csv")
raw_country = read.csv("country.csv")

###
###
### PREPROCESSING
###
###
# preprocessing genres data, using different variable to easy traceback later
pop_data = raw_pop
pop_data$genre = "pop"
pop_data$length = sapply(gregexpr("\\S+", pop_data$lyric), length)
pop_data$keep = pop_data$length > 50 
pop_data = pop_data[- grep("The Black Eyed Peas", pop_data$singer),]
pop_data = pop_data[pop_data$keep,]
pop_data = subset(pop_data, select = c(singer, song, lyric, genre, length))
pop_data = pop_data[c(1 : 1000), ]

rock_data = raw_rock
rock_data$genre = "rock"
rock_data$length = sapply(gregexpr("\\S+", rock_data$lyric), length)
rock_data$keep = rock_data$length > 50 
rock_data = rock_data[rock_data$keep,]
rock_data = subset(rock_data, select = c(singer, song, lyric, genre, length))
rock_data = rock_data[c(1 : 1000), ]

blues_data = raw_blues
blues_data$genre = "blues"
blues_data$length = sapply(gregexpr("\\S+", blues_data$lyric), length)
blues_data$keep = blues_data$length > 50 
blues_data = blues_data[blues_data$keep,]
blues_data = subset(blues_data, select = c(singer, song, lyric, genre, length))
blues_data = blues_data[c(1 : 1000), ]

country_data = raw_country
country_data$genre = "country"
country_data$length = sapply(gregexpr("\\S+", country_data$lyric), length)
country_data$keep = country_data$length > 50 
country_data = country_data[country_data$keep,]
country_data = subset(country_data, select = c(singer, song, lyric, genre, length))
country_data = country_data[c(1 : 1000), ]

rnb_data = raw_rnb
rnb_data$genre = "rnb"
rnb_data$length = sapply(gregexpr("\\S+", rnb_data$lyric), length)
rnb_data$keep = rnb_data$length > 50 
rnb_data = rnb_data[rnb_data$keep,]
rnb_data = subset(rnb_data, select = c(singer, song, lyric, genre, length))
rnb_data = rnb_data[c(1 : 1000), ]

hip_hop_data = raw_hip_hop
hip_hop_data$genre = "hip_hop"
hip_hop_data$length = sapply(gregexpr("\\S+", hip_hop_data$lyric), length)
hip_hop_data$keep = hip_hop_data$length > 50 
hip_hop_data = hip_hop_data[hip_hop_data$keep,]
hip_hop_data = subset(hip_hop_data, select = c(singer, song, lyric, genre, length))
hip_hop_data = hip_hop_data[c(1 : 1000), ]

# combine
set.seed(89)
combine_data = rbind(pop_data, rock_data, hip_hop_data,
	rnb_data, blues_data, country_data)
combine_data = combine_data[sample(nrow(combine_data)), ]
combine_data$genre = as.factor(as.numeric(levels(combine_data$genre)))

# preprocess text data

corpus = Corpus(VectorSource(combine_data$lyric))
corpus = tm_map(corpus, tolower)
corpus = tm_map(corpus, PlainTextDocument)
corpus = tm_map(corpus, removePunctuation)
corpus = tm_map(corpus, removeWords, stopwords("english"))
corpus = tm_map(corpus, stemDocument)
doc_terms_matrix = DocumentTermMatrix(corpus)

# remove sparse terms
sparse_dtm = removeSparseTerms(doc_terms_matrix, 0.995)
lyric_processed_data = as.data.frame(as.matrix(sparse_dtm))
col_name = c("col_1")
for (i in (2 : 1756)) {
	col_name = c(col_name, paste("col_", i, sep = ""))
}
colnames(lyric_processed_data) = col_name
lyric_processed_data$genre = as.factor(combine_data$genre)
lyric_processed_data$length = combine_data$length



# combine and split into training set and test set

split = sample.split(lyric_processed_data$genre, SplitRatio = 0.75)
training_set = subset(lyric_processed_data, split == T)
test_set = subset(lyric_processed_data, split == F)
# in case of the previous code not working well
# training_set = lyric_processed_data[c(1 : 4500), ]
# test_set = lyric_processed_data[c(4501 : 6000), ]

### 
###
### APPLY ML ALGORITHMS TO PROCESS DATA
###
###

##### decison tree

ptm <- proc.time()
rpart_predict = rpart(genre ~ ., 
	data = training_set, 
	method = "class", 
	minbucket = 10)
rpart_result = predict(rpart_predict, 
	type = "class", 
	newdata = test_set)
proc.time() - ptm
table(test_set$genre, rpart_result)

rpart_result_frame = as.data.frame(table(test_set$genre, rpart_result))
sum = 0
for (i in 1 : 6) {
	sum = sum + rpart_result_frame$Freq[7 * i - 6]
}
cat("The accuracy of this model is: ", sum, "/ 1500", (sum / 1500))

# randomForest

localH2O = h2o.init(nthreads = -1, max_mem_size = '40G')

train_rf_h2o = as.h2o(training_set)
test_rf_h2o = as.h2o(test_set)

ptm = proc.time()

name_x = setdiff(colnames(training_set), "genre")

rf_predict.regeression = h2o.randomForest(y = "genre", 
	x = name_x,
	training_frame = train_rf_h2o, 
	ntrees = 1000, 
	max_depth = 15, 
	min_rows = 10)

rf_fit.regeression = h2o.predict(object = rf_predict.regeression, 
	newdata = test_rf_h2o)

proc.time() - ptm

rf_result.regeression = as.data.frame(rf_fit.regeression)

table(test_set$genre, rf_result.regeression$predict)

# gbm

localH2O = h2o.init(nthreads = -1, max_mem_size = '40G')

train_gbm_h2o = as.h2o(training_set)
test_gbm_h2o = as.h2o(test_set)

ptm = proc.time()

name_x = setdiff(colnames(training_set), "genre")

gbm_predict.regeression = h2o.gbm(y = "genre", 
	x = name_x,
	training_frame = train_gbm_h2o, 
	ntrees = 1000, 
	max_depth = 15, 
	min_rows = 10)

gbm_fit.regeression = h2o.predict(object = gbm_predict.regeression, 
	newdata = test_gbm_h2o)

proc.time() - ptm

gbm_result.regeression = as.data.frame(gbm_fit.regeression)

table(test_set$genre, gbm_result.regeression$predict)


##### neural network using h2o

localH2O = h2o.init(nthreads = -1, max_mem_size = '40G', 
	enable_assertions = F)

train_nn_h2o = as.h2o(training_set)
test_nn_h2o = as.h2o(test_set)

ptm = proc.time()
name_x = setdiff(colnames(training_set), "genre")
nn_predict.regeression1 = h2o.deeplearning(y = "genre", 
	x = name_x,
	training_frame = train_nn_h2o, 
	hidden = c(1000, 100))

nn_fit.regeression1 = h2o.predict(object = nn_predict.regeression1, 
	newdata = test_nn_h2o)
proc.time() - ptm

nn_result.regeression1 = as.data.frame(nn_fit.regeression1)


table(test_set$genre, 
	nn_result.regeression1$predict)


#######

ptm <- proc.time()
nn_predict.regeression2 = h2o.deeplearning(y = "genre", 
	x = name_x,
	training_frame = train_nn_h2o, 
	hidden = c(500, 50))

nn_fit.regeression2 = h2o.predict(object = nn_predict.regeression2, 
	newdata = test_nn_h2o)

nn_result.regeression2 = as.data.frame(nn_fit.regeression2)
proc.time() - ptm


table(test_set$genre, 
	nn_result.regeression2$predict)

########

ptm <- proc.time()
nn_predict.regeression3 = h2o.deeplearning(y = "genre", 
	x = name_x,
	training_frame = train_nn_h2o, 
	hidden = c(5000, 2000))

nn_fit.regeression3 = h2o.predict(object = nn_predict.regeression3, 
	newdata = test_nn_h2o)

nn_result.regeression3 = as.data.frame(nn_fit.r
	egeression3)
proc.time() - ptm


table(test_set$genre, 
	nn_result.regeression3$predict)

#########

ptm <- proc.time()
nn_predict.regeression4 = h2o.deeplearning(y = "genre", 
	x = name_x,
	training_frame = train_nn_h2o, 
	hidden = c(10000, 5000))

nn_fit.regeression4 = h2o.predict(object = nn_predict.regeression4, 
	newdata = test_nn_h2o)

nn_result.regeression4 = as.data.frame(nn_fit.regeression4)
proc.time() - ptm


table(test_set$genre, 
	nn_result.regeression4$predict)

#### this code need to change somewhat

# neuralnet_result_frame1 = as.data.frame(table(test_set$genre, 
# 	nn_result.regeression1$predict))
# sum = 0
# for (i in 1 : 26) {
# 	sum = sum + neuralnet_result_frame1$Freq[27 * i - 26]
# }
# cat("The accuracy of 1st model is: ", sum, "/ 1500", (sum / 1500))
# 
# neuralnet_result_frame2 = as.data.frame(table(test_set$genre, 
# 	nn_result.regeression2$predict))
# sum = 0
# for (i in 1 : 26) {
# 	sum = sum + neuralnet_result_frame2$Freq[27 * i - 26]
# }
# cat("The accuracy of 2nd model is: ", sum, "/ 1500", (sum / 1500))



































