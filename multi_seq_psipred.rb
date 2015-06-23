#! /bin/env ruby

require 'bio'
require 'getoptlong'

####################################################
infile=nil
outdir='psipred_multi_seq_outdir'+$$.to_s
blastdb=''
visualization=nil

get_proportion_prog = 'get_sec_struc_proportion.rb'
outfile_arr=[]
#method_arr = ['psipred', 'netsurfp']
method_arr=[]
psipred_prog=nil
netsurfp_prog=nil
max_struc_rela={}

####################################################
def show_Help()
  puts "Usage of #{$0}:"
  print "ruby #{$0} <--infile=infile> <(--psipred|--netsurfp)=prediction_prog>\n"
  print "Options:\n"
  puts "\t[--outdir=]                default: psipred_multi_seq_outdir$$"
  puts "\t[--blastdb]                only effective for psipred"
  puts "\t[--get_proportion_prog]    the Ruby script named 'get_proportion_prog.rb'
                                   default: get_proportion_prog.rb"
  puts "\t[-h|--help]"
  puts "\t[-v|--visualization]"
  exit
end

####################################################
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--visualization', '-v', GetoptLong::NO_ARGUMENT],
  [ '--infile', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--outdir', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--psipred', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--netsurfp', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--blastdb', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--get_proportion_prog', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt, arg|
  case opt
    when '-h', '--help'
      show_Help()
    when '-v', '--visualization'
      visualization = 1
    when '--infile'
      infile=arg
    when '--outdir'
      outdir=arg
    when '--psipred'
      psipred_prog=File.expand_path(arg)
      method_arr.push('psipred')
    when '--netsurfp'
      netsurfp_prog=File.expand_path(arg)
      method_arr.push('netsurfp')
    when '--blastdb'
      blastdb=arg
    when '--get_proportion_prog'
      get_proportion_prog=arg+'.rb'
  end
end

if (! Dir.exist?(outdir)) then
  Dir.mkdir(outdir)
end
load get_proportion_prog

(raise "Prediction method has not be specified. Exiting ......"; exit 1) if method_arr.size == 0
#blastdb=File.expand_path(blastdb)

#####################################################
#ff = Bio::FastaFormat.open(infile)
ff = Bio::FlatFile.open(infile)
ff.each_entry do |f|
  f.definition =~ /([^| ]+)/;
  f_title_no_space = $1
  outfasta = outdir + '/' + f_title_no_space + '.fasta'
  outfasta = File.expand_path(outfasta)
  outfile  = outdir + '/' + f_title_no_space + '.ss'
  outfile  = File.expand_path(outfile)
  outfile_arr.push(outfile)
  out_obj=File.open(outfasta, 'w')
  out_obj.puts ">" + f.definition
  out_obj.puts f.naseq
  out_obj.close
  method_arr.each do |i|
    if i then
      cmd=nil
      case i
        when 'psipred'
          cmd = "cd #{outdir}; #{psipred_prog} #{outfasta} #{blastdb}"
        when 'netsurfp'
          cmd = "#{netsurfp_prog} -i #{outfasta} -J #{outfile}"
          max_struc_rela={0=>'alpha',1=>'beta',2=>'coil'}
      end
      if visualization then
        puts "cmd is:\t" + cmd
        system "#{cmd}"
      else
        `#{cmd}`
      end
    end
  end
end

outfile_arr.each do |file_name|
  outfile_obj = Protein_Sec_Struc_Outfile.new()
  outfile_obj.file_name = file_name
  puts outfile_obj.get_proportion(max_struc_rela).map{|x| x[1]}.join("\t")
end


