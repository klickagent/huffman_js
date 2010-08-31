# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

asyncLoop = require("./core_helpers").asyncLoop
isArray = require("./core_helpers").isArray
huffmanTree = require("./tree")

# The TreeBuilder class provides a easy way to generate a Huffman Binary Tree
# based on a given text.
class TreeBuilder
	# Create the TreeBuilder, the text argument will be used to build the
	# optimized tree
	constructor: (@text) ->
	
	# Build the tree optimized for text
	build: (callback) ->
		@buildFrequencyTable (frequencyTable) =>
			@combineTable frequencyTable, (combinedList) =>
				@compressCombinedTable combinedList, (compressed) ->
					huffmanTree.decodeTree(compressed, callback)
	
	# Create a frequency table of characteres into text, and return an array with
	# chars and frequency of each one, sorted by frequency ascending, for example,
	# the string "hello" will return: [[1, 'h'], [1, 'e'], [1, 'o'], [2, 'l']]
	buildFrequencyTable: (callback) ->
		tableHash = {}
		i = 0
		
		asyncLoop (next) =>
			if i < @text.length
				chr = @text.charAt(i)
				tableHash[chr] ?= 0
				tableHash[chr] += 1
				i++
				next()
			else
				table = []

				for chr, frequency of tableHash
					table.push [frequency, chr]

				table.sort @frequencySorter
				callback(table)
	
	# Sorter function to keep table balanced
	frequencySorter: (a, b) -> if a[0] > b[0] then 1 else (if a[0] < b[0] then -1 else 0)
	
	# Combine frequency table into a nested structure for building the tree
	combineTable: (table, callback) ->
		asyncLoop (next) ->
			if table.length > 1
				first = table.shift()
				second = table.shift()
				table.push([first[0] + second[0], [first, second]])
				table.sort @frequencySorter
				next()
			else
				callback(table[0])
	
	# Compress the final table into a simple structure of array
	compressCombinedTable: (table, cb) ->
		combineValue = (value, callback) ->
			if isArray(value)
				process.nextTick ->
					combineValue value[0][1], (v0) ->
						combineValue value[1][1], (v1) ->
							callback([v0, v1])
			else
				callback(value)
		
		combineValue(table[1], cb)

module.exports = TreeBuilder
