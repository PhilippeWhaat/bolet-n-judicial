#! /usr/bin/ruby

require 'open-uri'

#date = "%02d%02d%d1" % [Date.today.day, Date.today.month, Date.today.year]
date = "%02d%02d%d1" % [20, Date.today.month, Date.today.year]

filename = "pdfs/#{date}.pdf"
unlocked_filename = "pdfs/#{date}_unlocked.pdf"

url = "http://www.poderjudicialdf.gob.mx/work/models/PJDF/boletin_repositorio/#{date}.pdf"


puts "Downloading #{date}.pdf"

open(filename, 'wb') do |file|
  file << open(url).read
end

searches = File.read('search.txt').split("\n").reject { |c| c.empty? }
searches.map! { |s| s.split(",") }

puts "Unencrypting PDF"

%x( qpdf --decrypt #{filename} #{unlocked_filename})

text = %x( pdftotext -raw #{unlocked_filename} - )

text = text[text.index('PRIMERO DE LO CIVIL')..-1].force_encoding("iso-8859-1").gsub "\n", " "

entries = text.scan(/.*?Exp\. \d+\/\d+\.?/m)

searches.each { |s|
  puts "Searching for #{s[0]}"
  filtered = entries.select { |e| e.include? s[0] and e.include? s[1]}
  puts " #{ filtered.count }"
  puts filtered
}

