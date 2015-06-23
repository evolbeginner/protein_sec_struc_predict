#! /bin/env ruby
require 'getoptlong'

####################################################
outfile_arr=[]

####################################################
def show_Help()
  print "#{$0}: get proportion for each type of protein secondary structural element\n"
  print "Usage: ruby #{$0}"
  print <<EOF
  <--infile=> [-h|--help]
  Note: multiple infiles are allowable
EOF
  puts
  exit 1
end

class String
  def is_number?()
    true if Float(self) rescue false
  end
end


class Protein_Sec_Struc_Outfile
  attr_accessor :file_name
  def get_proportion(max_struc_rela={0=>'coil', 1=>'alpha', 2=>'beta'})
    sum = 0
    max = [0] * 3
    #max_struc_rela = {0=>'coil', 1=>'alpha', 2=>'beta'}
    proportion={} # e.g. proportion['coil'] = 0.45 ......
    ff = File.open(file_name, 'r')
    while(line=ff.gets) do
      line=line.chomp!
      is_sec_info = 0 # check whether the line being read contains secondary structure info
      last_3_column = []
      line_arr = line.split
      last_3_column = line_arr.reverse[0,3]
      last_3_column.each{|x| (is_sec_info=1; next ) if (! x.is_number?)}
      next if is_sec_info == 1
      max[last_3_column.each_with_index.max[1]] += 1
    end
    
    sum = max.inject{|sum2,x| sum2 + x }
    max.each_with_index do |value, index|
      proportion[max_struc_rela[index]] = max[index].to_f/sum.to_f
      #print index, "\t", value, "\t", proportion[max_struc_rela[index]] + "\n"
    end

    return(proportion.sort_by{|k,v|k})
  end
end

####################################################
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--infile', GetoptLong::REQUIRED_ARGUMENT ],
)

opts.each do |opt, arg|
  case opt
    when '--infile'
      outfile_arr.push(arg)
    when '--help', '-h'
      show_Help()
  end
end

#####################################################
outfile_arr.each do |file_name|
  outfile_obj = Protein_Sec_Struc_Outfile.new()
  outfile_obj.file_name = file_name
  puts outfile_obj.get_proportion().map{|x| x[1]}.join("\t")
end

