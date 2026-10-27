# Checks the complete serialized XML relationship without installing either layout.
require 'digest'
root=File.expand_path('..',__dir__)
reference=File.join(root,'reference/Bulgarian-Phonetic.keylayout')
custom=File.join(root,'layouts/Bulgarian-Phonetic-Windows.keylayout')
old_xml=File.binread(reference).force_encoding('UTF-8')
new_xml=File.binread(custom).force_encoding('UTF-8')
count=0
maps=old_xml.scan(/<keyMap index="(\d+)">/).flatten.map(&:to_i)
abort 'Unexpected modifier map indices' unless maps==(0...maps.length).to_a && !maps.empty?
abort 'Expected 256 explicit modifier selectors' unless old_xml.scan('<keyMapSelect ').length==256
expected=old_xml.gsub(/<key code="(10|50)" action="a(\d+)_(10|50)"\/>/) do
  key,mods,from=$1,$2,$3
  abort 'Reference contains an unexpected mapping' unless key==from && maps.include?(mods.to_i)
  count+=1
  destination=key=='10' ? '50' : '10'
  "<key code=\"#{key}\" action=\"a#{mods}_#{destination}\"/>"
end
abort "Expected #{maps.length*2} key entries, got #{count}" unless count==maps.length*2
before='id="19529" name="Bulgarian - Phonetic"'
after='id="19530" name="Bulgarian - Phonetic Windows"'
abort 'Reference metadata missing' unless expected.scan(before).length==1
expected=expected.sub(before,after)
abort 'Unexpected additional XML changes' unless expected==new_xml
diff=IO.popen(['/usr/bin/diff','-u','--label','a/Bulgarian-Phonetic.keylayout','--label','b/Bulgarian-Phonetic-Windows.keylayout',reference,custom], &:read)
abort 'diff command failed' unless $?.exitstatus==1
abort 'Published patch does not match the files' unless diff==File.read(File.join(root,'proof/keyboard-layout.diff'))
File.readlines(File.join(root,'SHA256SUMS'),chomp:true).each do |line|
  hash,path=line.split(/\s+/,2)
  abort "Hash mismatch: #{path}" unless Digest::SHA256.file(File.join(root,path)).hexdigest==hash
end
puts "PASS: only #{count} key references (two keys × #{maps.length} unique maps), layout name and layout ID differ."
puts 'All 256 explicit modifier selectors are identical between the two files.'
puts 'All other XML bytes are identical. The published unified diff and SHA-256 manifest match.'
