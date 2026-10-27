# Export the local Apple layout into comparable original/custom XML.
# Writes files only to the requested output directory. Does not install or activate.
require_relative 'keyboard_api'
require 'fileutils'
require 'digest'
abort 'Usage: ruby tools/build.rb OUTPUT_DIRECTORY' unless ARGV.length==1
out=File.expand_path(ARGV[0])
library=File.expand_path('~/Library')
abort 'Choose a build directory outside Library and /System.' if out==library || out.start_with?(library+'/','/Library/','/System/')
paths=['Bulgarian-Phonetic.keylayout','Bulgarian-Phonetic-Windows.keylayout','keyboard-layout.diff']
abort 'Output files already exist; choose an empty build directory.' if paths.any? {|name| File.exist?(File.join(out,name))}
kb=KeyboardAPI
source=kb.sources.find {|s| kb.id(s)=='com.apple.keylayout.Bulgarian-Phonetic'}
abort 'Apple Bulgarian Phonetic source not found.' unless source
header=kb.data(source)[0,40].unpack('S<S<L<L<L<L<L<L<L<L<')
abort 'Unexpected source format; inspect before exporting.' unless header[3]==1
states=[0]; tables={}
states.each do |state|
  tables[state]=(0...256).map do |mods|
    (0...128).map do |key|
      result=kb.transition(source,key,mods,state)
      states << result[1] unless states.include?(result[1])
      abort 'Unexpectedly large state graph.' if states.length>32
      result
    end
  end
end
def escape_output(text)
  text.codepoints.map {|c| c<32 || c==127 || [34,38,60,62].include?(c) ? "&#x#{c.to_s(16).upcase};" : c.chr(Encoding::UTF_8)}.join
end
unique_maps=[]
selectors=(0...256).map do |mods|
  signature=states.map {|state| tables[state][mods]}
  index=unique_maps.index(signature)
  unless index
    index=unique_maps.length
    unique_maps << signature
  end
  index
end
def export_xml(kb,source,unique_maps,selectors,states,swap)
  name=swap ? 'Bulgarian - Phonetic Windows' : 'Bulgarian - Phonetic'
  id=swap ? 19530 : 19529
  xml=['<?xml version="1.0" encoding="UTF-8"?>','<!DOCTYPE keyboard SYSTEM "file://localhost/System/Library/DTDs/KeyboardLayout.dtd">',"<keyboard group=\"7\" id=\"#{id}\" name=\"#{name}\" maxout=\"2\">",'  <layouts><layout first="0" last="255" mapSet="main" modifiers="modifiers"/></layouts>','  <modifierMap id="modifiers" defaultIndex="0">']
  256.times do |mods|
    keys={1=>'command',2=>'shift',4=>'caps',8=>'option',16=>'control',32=>'rightShift',64=>'rightOption',128=>'rightControl'}.select {|bit,_| mods & bit != 0}.values.join(' ')
    xml << "    <keyMapSelect mapIndex=\"#{selectors[mods]}\"><modifier keys=\"#{keys}\"/></keyMapSelect>"
  end
  xml << '  </modifierMap>' << '  <keyMapSet id="main">'
  unique_maps.length.times do |mods|
    xml << "    <keyMap index=\"#{mods}\">"
    128.times do |key|
      from=swap ? {10=>50,50=>10}.fetch(key,key) : key
      xml << "      <key code=\"#{key}\" action=\"a#{mods}_#{from}\"/>"
    end
    xml << '    </keyMap>'
  end
  xml << '  </keyMapSet>' << '  <actions>'
  unique_maps.length.times do |mods|
    128.times do |key|
      xml << "    <action id=\"a#{mods}_#{key}\">"
      states.each_with_index do |state,state_index|
        output,next_state=unique_maps[mods][state_index][key]
        state_name=state==0 ? 'none' : "s#{state}"
        result="output=\"#{escape_output(output)}\""
        result+=" next=\"s#{next_state}\"" unless next_state==0
        xml << "      <when state=\"#{state_name}\" #{result}/>"
      end
      xml << '    </action>'
    end
  end
  xml << '  </actions>' << '  <terminators>'
  states.reject(&:zero?).each do |state|
    output,next_state=kb.transition(source,53,0,state)
    abort 'Unexpected terminator; inspect source.' unless next_state==0 && output.end_with?("\e")
    xml << "    <when state=\"s#{state}\" output=\"#{escape_output(output[0...-1])}\"/>"
  end
  xml << '  </terminators>' << '</keyboard>'
  xml.join("\n")+"\n"
end
FileUtils.mkdir_p(out)
[false,true].each_with_index do |swap,i|
  path=File.join(out,paths[i])
  File.write(path,export_xml(kb,source,unique_maps,selectors,states,swap))
  puts "#{Digest::SHA256.file(path).hexdigest}  #{paths[i]}"
end
patch=IO.popen(['/usr/bin/diff','-u','--label','a/Bulgarian-Phonetic.keylayout','--label','b/Bulgarian-Phonetic-Windows.keylayout',File.join(out,paths[0]),File.join(out,paths[1])], &:read)
abort 'diff failed' unless $?.exitstatus==1
File.write(File.join(out,paths[2]),patch)
puts "Built from #{kb.id(source)}, keyboard type #{kb.LMGetKbdType()}; states #{states.inspect}."
puts "256 distinct modifier masks select #{unique_maps.length} unique character maps."
puts 'No input sources or preferences were changed.'
