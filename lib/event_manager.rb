require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phonenumber(phonenumber)
  trimmed_number = phonenumber.to_s.tr('^0-9','')
    if trimmed_number.length <10 || trimmed_number.length >11
      'bad number'
    elsif trimmed_number[0] == '1' && trimmed_number.length == 11
      trimmed_number[0] = ''
      trimmed_number
    elsif trimmed_number[0] != '1' && trimmed_number.length == 11
      'bad number'
    else 
      trimmed_number
    end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin 
    civic_info.representative_info_by_address(
      address:  zip,
      levels: 'country',
      roles: ['legislatorUpperBody','legislatorLowerBody']
    ).officials
  rescue 
    'No zip'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end
  

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open( 
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol,
)
popular_hours = Hash.new(0)
popular_dates = Hash.new(0)
  
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phonenumber = clean_phonenumber(row[:homephone])
  hours = row[:regdate].split(":")[0][-2..-1]
  popular_hours[hours] += 1
  date = Date.strptime(row[:regdate].split(' ')[0].insert(-3,"20"),"%m/%d/%Y").wday
  popular_dates[date] += 1
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end
puts popular_hours
puts popular_dates
