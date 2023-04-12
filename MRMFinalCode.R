###My directory structure
###Project (In this case: Demo)
###Sub-folders: Code, Data, Result, Literature, Manuscript


###First, I change the working directory to the overall project folder
setwd("/Users/ewoudcornelissen/Documents/Mixed research methods/Article pdf's")


###Read the input file
###On my system, the file is stored in the sub-folder data
ports <- readtext::readtext("*.pdf")

#To remove unwanted characters, modify the following function
ports$text <- stringi::stri_replace_all_regex(ports$text, "\\b[0-9]+(st|nd|rd|th)?\\b", " ")
ports$text <- stringi::stri_replace_all_regex(ports$text, "\\b[[:alpha:]]{1,2}\\b", " ")
ports$text[[1]]

###Use parts of speech (POS) tagging to understand the data; Install 'udpipe' package first
library(lattice)
library(udpipe)

#Download the UDPipe model for your language
udmodel <- udpipe_download_model(language = "english")
#Check the current working directory for the model file name to be used below
udmodel_english <- udpipe_load_model(file = 'english-ewt-ud-2.5-191206.udpipe')

#Annotate the data
ports_model <- udpipe_annotate(udmodel_english, ports$text)
#Convert to a data frame
ports_annotated <- data.frame(ports_model)

#Use the txt_freq function in udpipe library to check counts
pos_freq <- txt_freq(ports_annotated$upos)
#Sort in decreasing order
pos_freq$key <- factor(pos_freq$key, levels = rev(pos_freq$key))
#Plot on a bar chart
barchart(key ~ freq, data = pos_freq, main = "Parts of Speech", xlab = "Freq")


#Examine nouns in the data
noun_freq <- subset(ports_annotated, upos %in% c("NOUN")) 
noun_freq <- txt_freq(noun_freq$token)
noun_freq$key <- factor(noun_freq$key, levels = rev(noun_freq$key))
barchart(key ~ freq, data = head(noun_freq, 20), main = "Most occurring nouns", xlab = "Freq")


#Examine adjectives in the data
adj_freq <- subset(ports_annotated, upos %in% c("ADJ")) 
adj_freq <- txt_freq(adj_freq$token)
adj_freq$key <- factor(adj_freq$key, levels = rev(adj_freq$key))
barchart(key ~ freq, data = head(adj_freq, 20), main = "Most occurring adjectives", xlab = "Freq")


#Examine verbs in the data
verb_freq <- subset(ports_annotated, upos %in% c("VERB")) 
verb_freq <- txt_freq(verb_freq$token)
verb_freq$key <- factor(verb_freq$key, levels = rev(verb_freq$key))
barchart(key ~ freq, data = head(verb_freq, 20), main = "Most occurring Verbs", xlab = "Freq")


#Examine proper nouns in the data
proper_noun <- ports_annotated$lemma[ports_annotated$upos == "PROPN"]
proper_noun <- unique(proper_noun)
#write.csv(phrase, "proper_noun.csv")


###Co-occurrence for adjectives and nouns only
ports_cooc <- cooccurrence(subset(ports_annotated, upos %in% c("NOUN", "ADJ")), 
                     term = "lemma", 
                     group = c("doc_id", "paragraph_id", "sentence_id"))
head(ports_cooc, 15)


library(igraph)
library(ggraph)
library(ggplot2)
wordnetwork <- head(ports_cooc, 30)
wordnetwork <- graph_from_data_frame(wordnetwork)
ggraph(wordnetwork, layout = "fr") +
  geom_edge_link(aes(edge_alpha = cooc)) +
  geom_node_text(aes(label = name), size = 4) +
 theme(legend.position = "none")



#Identify keywords using RAKE (Rapid Automatic Keyword Extraction technique)
kw_rake <- keywords_rake(x = ports_annotated, 
                         term = "lemma", 
                         group = c("doc_id", "paragraph_id", "sentence_id"), 
                         relevant = ports_annotated$upos %in% c("NOUN", "ADJ"), 
                         ngram_max = 5, n_min = 2)

#Select key terms consisting of more than one word
kw_rake <- kw_rake[kw_rake$ngram > 1,]

#Create factor variable for bar chart
kw_rake$key <- factor(kw_rake$keyword, levels = rev(kw_rake$keyword))
barchart(key ~ rake, data = head(kw_rake, 15), main = "Keywords identified by RAKE", xlab = "Rake")


#Identify commonly occurring noun phrases
ports_annotated$phrase_tag <- as_phrasemachine(ports_annotated$upos, type = "upos")
kw_phrase <- keywords_phrases(x = ports_annotated$phrase_tag,
                              term = ports_annotated$lemma,
                              pattern = "(A|N)*N(P+D*(A|N)*N)*",
                              is_regex = TRUE, detailed = FALSE)

#Select key terms consisting of more than one word
kw_phrase <- kw_phrase[kw_phrase$ngram > 1 & kw_phrase$freq > 1,]

#Create factor variable for bar chart
kw_phrase$key <- factor(kw_phrase$keyword, levels = rev(kw_phrase$keyword))
barchart(key ~ freq, data = head(kw_phrase, 15), main = "Keywords - simple noun phrases", xlab = "Frequency")


ports_phrase <- dplyr::bind_rows(kw_phrase, kw_rake)

## Recode terms to phrases
ports_annotated$term <- ports_annotated$token

ports_annotated$term <- txt_recode_ngram(ports_annotated$term,
                                             compound = ports_phrase$keyword, 
                                             ngram = ports_phrase$ngram)

ports_annotated <- ports_annotated[!is.na(ports_annotated$term),  ]

#Delete verb, punct, adp, det...
## Keep keyword or just plain nouns
ports_annotated$term <- ifelse(ports_annotated$upos %in% c("NOUN"), ports_annotated$lemma,
                                   ifelse(ports_annotated$term %in% ports_phrase$keyword, 
                                          ports_annotated$term, NA))

ports_annotated <- ports_annotated[!is.na(ports_annotated$term),  ]


## Build document/term/matrix

library(dplyr)
library(tidytext)

ports_dtm <- 
  ports_annotated  %>%
  select(doc_id, term) %>%
  group_by(doc_id) %>%
  count(term, sort = TRUE) %>%
  tidytext::cast_dtm(doc_id, term, n)

m <- as.matrix(ports_dtm)
v <- sort(colSums(m),decreasing = TRUE)
d <- data.frame(word = names(v),freq=v)

set.seed(007)
wordcloud::wordcloud(words = d$word, freq = d$freq, max.words=50)


###Run a topic model for select terms

library(stm)

#Earlier, we had used the function 'textprocessor' as the first step for the structural topic model 
#To use the DTM created using UDPipe (rather than raw text) as an input to structural topic model,
#we use the function 'readCorpus' in the package stm
stmInput <- readCorpus(ports_dtm, type="slam")

#Prepare documents for analysis; only terms which occurr in at least two documents will be selected because of lower.thresh = 1
stmData  <- prepDocuments(stmInput$documents, stmInput$vocab, stmInput$meta, lower.thresh = 1)

#See how different values of k affect information criteria
stm_k_3_20 <- searchK(stmData$documents, stmData$vocab, K = seq(3, 20, by = 1), data = stmData$meta, init.type = "Spectral")
plot(stm_k_3_20)



k <- 9
set.seed(2021)
stmOutput <- stm::stm(stmData$documents, stmData$vocab, K = k, data = stmData$meta, init.type = "Spectral")

#See the output of the model
plot.STM(stmOutput, type = "summary", xlim = c(0.0, 1.0), n = 8)

#See the top words for each topic. The highest probability and FREX words are usually most interesting
#Lift and Score are two other algorithms for determining the key words in each topic
labelTopics(stmOutput, c(1:k))

#Check topic correlation
stmTopicCorr <- topicCorr(stmOutput)
plot.topicCorr(stmTopicCorr)

