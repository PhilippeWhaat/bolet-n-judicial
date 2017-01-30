#! /usr/bin/ruby

require 'sendgrid-ruby'
require 'open-uri'

date = "%02d%02d%d1" % [Date.today.day, Date.today.month, Date.today.year]
#date = "%02d%02d%d1" % [20, Date.today.month, Date.today.year]

filename = "pdfs/#{date}.pdf"
unlocked_filename = "pdfs/#{date}_unlocked.pdf"

url = "http://www.poderjudicialdf.gob.mx/work/models/PJDF/boletin_repositorio/#{date}.pdf"

puts "Downloading #{date}.pdf"

open(filename, 'wb') do |file|
  file << open(url).read
end

puts "Unencrypting PDF"

%x( qpdf --decrypt #{filename} #{unlocked_filename})

text = %x( pdftotext -raw #{unlocked_filename} - )

text = text[text.index('PRIMERO DE LO CIVIL')..-1].force_encoding("iso-8859-1").gsub "\n", " "

entries = text.scan(/.*?Exp\. \d+\/\d+\.?/m)

output = ''

#START OF TEAM SEARCH
searches = File.read('search.txt').split("\n").reject { |c| c.empty? }
searches.map! { |s| s.split(",") }
acdo = 0
output += "LISTA DE ACUERDOS PARA EL EQUIPO 1\n\n"

searches.each { |s|
  filtered = entries.select { |e| e.downcase.include? s[0].downcase.encode("ISO-8859-1") and e.include? s[1]}
  if filtered.count!=0
  	output += "Resultado por '#{s[0]}' Núm. Exp. #{s[1]} (#{s[2]} SEC. #{s[3]}):\n\n".encode("ISO-8859-1"); output.encode("UTF-8")
  	output += " #{ filtered.count }"
  	output += filtered.join "\n\n"
  	output += "\n\n\n"
  	acdo = acdo+1
  end
}
if acdo ==0
  	output += "No se ha encontrado ningún acuerdo\n\n".encode("ISO-8859-1"); output.encode("UTF-8")
end
#END OF TEAM SEARCH

puts output

include SendGrid

from = Email.new(email: 'BJGS-UP@up.edu.mx')
subject = 'Lista de acuerdos del %02d/%02d/%d' % [Date.today.day, Date.today.month, Date.today.year]
to = Email.new(email: 'philippe.tritto@gmail.com')
content = Content.new(type: 'text/plain', value: output)
mail = Mail.new(from, subject, to, content)

sendgrid_api_key = File.read('sendgrid_api_key.txt').chomp

sendgrid = SendGrid::API.new(api_key: sendgrid_api_key)
response = sendgrid.client.mail._('send').post(request_body: mail.to_json)

puts response.status_code
puts response.body
puts response.headers

File.delete("pdfs/#{date}.pdf")
File.delete("pdfs/#{date}_unlocked.pdf")