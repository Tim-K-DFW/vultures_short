require 'pry'
require 'date'
require 'json'
load 'helpers.rb'
Dir["Classes/*.rb"].each { |file| load file }

case ARGV[0]
when 'output_only'
  ReportPrinter.new(JSON.parse(File.read('result.txt'))).generate
when 'debug'
  data_table = load_data(debug: true)
  results = Engine.new(data_table, engine_params_hardcoded).perform
    File.open("result.txt", "w") { |file| file.write(results.to_json) }
    puts 'JSON results saved to result.txt.'
    filename = ReportPrinter.new(results).generate
    puts "Full report saved to #{filename}."
    puts '--------------------------------------------------------'
else
  data_table = load_data
  # data_table = PriceTable.new
  begin
    results = Engine.new(data_table, engine_params).perform
    File.open("result.txt", "w") { |file| file.write(results.to_json) }
    puts 'JSON results saved to result.txt.'
    filename = ReportPrinter.new(results).generate
    puts "Full report saved to #{filename}."
    puts '--------------------------------------------------------'
  end until !another_run?
end
