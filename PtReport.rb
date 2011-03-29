require 'rubygems'
require 'fastercsv'
require 'date'


  # Return an array of the lables, all white space removed, as an array.
  def tags(row)
    row[:labels].split(',').map! {|x| x.strip}
  end


the_CSV_file = ARGV[0] || 'sample_pt.csv'
the_sprint = ARGV[1] || 47

# module FasterCSV do
#   class Row do
#     def accepted?() do
#       return field('Current State' == 'Accepted')
#     end
#   end
# end
# 
puts "Sprint data from #{the_CSV_file} for sprint #{the_sprint}"

data_table = FasterCSV.read(the_CSV_file, :headers => true, :header_converters => :symbol, :converters => :numeric)

# Strip out all but the required sprint's data.
data_table.delete_if() do |row|
  row[:iteration] != the_sprint
end

# Get the date range of the sprint (from the first story, though could get it from any of them)
iteration_start = Date.parse(data_table[0][:iteration_start])
iteration_end = Date.parse(data_table[0][:iteration_end])
puts "iteration start: #{iteration_start}, end: #{iteration_end}"

# So we now have a table with just the stories from this sprint, so go through the lot, adding up some totals (cumulative and day-by-day)
ttl_effort = ttl_scheduled = ttl_unsprinted = ttl_unplanned = ttl_chaos = 0
accepted = 0

day_totals = Hash.new()
(iteration_start .. iteration_end).each do |day|
  day_totals[day.to_s] = Hash.new
  day_totals[day.to_s][:chaos] = 0
  day_totals[day.to_s][:unplanned] = 0
  day_totals[day.to_s][:unsprinted] = 0
  day_totals[day.to_s][:scheduled] = 0
end

data_table.each() do |row|
  ttl_effort += row[:estimate]
  is_accepted = (row[:current_state] == 'accepted')
  this_day = Date.parse(row[:accepted_at]).to_s if is_accepted
  
  if tags(row).include? 'unsprinted' then
    if tags(row).include? 'unplanned' then
      ttl_chaos += row[:estimate]  #unsprinted and unplanned = chaos
      day_totals[this_day][:chaos] += row[:estimate] if is_accepted
    else
      ttl_unsprinted += row[:estimate]  #unsprinted and planned = implementation work
      day_totals[this_day][:unsprinted] += row[:estimate] if is_accepted
    end
  else
    if tags(row).include? 'unplanned' then
      ttl_unplanned += row[:estimate] #unplanned but not unsprinted
      day_totals[this_day][:unplanned] += row[:estimate] if is_accepted
    else
      ttl_scheduled += row[:estimate] # not unplanned and not unsprinted = scheduled
      day_totals[this_day][:scheduled] += row[:estimate] if is_accepted
    end
  end
end

# Cumulative totals to output
cum_scheduled = cum_unsprinted = cum_unplanned = cum_chaos = 0
#-------
# Output the data for import into a spreadsheet
puts "Totals"
puts "Effort, #{ttl_effort}"
puts "Scheduled, #{ttl_scheduled}"
puts "Unsprinted, #{ttl_unsprinted}"
puts "Unplanned, #{ttl_unplanned}"
puts "Chaos, #{ttl_chaos}"
puts "Settings"
puts "Sprint, #{the_sprint}"
puts "Start, #{iteration_start.to_s}"
puts "End, #{iteration_end.to_s}"

puts "Day, scheduled, unsprinted, unplanned, chaos"
(iteration_start .. iteration_end).each do |day|
  puts "#{day},#{cum_scheduled += day_totals[day.to_s][:scheduled]},#{cum_unsprinted += day_totals[day.to_s][:unsprinted]},#{cum_unplanned += day_totals[day.to_s][:unplanned]},#{cum_chaos += day_totals[day.to_s][:chaos]}"
end

