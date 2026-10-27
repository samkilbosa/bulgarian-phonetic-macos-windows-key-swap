# Read-only native comparison. Requires the custom source to be registered in macOS.
require_relative 'keyboard_api'
require 'digest'
abort 'Usage: ruby tools/verify_runtime.rb [--all-modifiers]' unless ARGV.empty? || ARGV==['--all-modifiers']
modifier_count=256
kb=KeyboardAPI
original=kb.sources.find {|s| kb.id(s)=='com.apple.keylayout.Bulgarian-Phonetic'}
custom=kb.sources.find {|s| kb.id(s)=='org.unknown.keylayout.Bulgarian-PhoneticWindows'}
abort 'Original Apple Bulgarian Phonetic input source not found.' unless original
abort 'Custom layout not found. Install/add it in Keyboard settings, then retry.' unless custom
root=File.expand_path('..',__dir__)
packaged=File.join(root,'layouts/Bulgarian-Phonetic-Windows.keylayout')
installed=File.expand_path('~/Library/Keyboard Layouts/Bulgarian-Phonetic-Windows.keylayout')
abort 'Installed file missing or different from the repository artifact.' unless File.file?(installed) && File.binread(installed)==File.binread(packaged)
puts "macOS: #{IO.popen(['/usr/bin/sw_vers','-productVersion'], &:read).strip}"
puts "Build: #{IO.popen(['/usr/bin/sw_vers','-buildVersion'], &:read).strip}"
puts "Keyboard type: #{kb.LMGetKbdType()}"
puts "Original source: #{kb.id(original)}"
puts "Custom source: #{kb.id(custom)}"
puts "Layout SHA-256: #{Digest::SHA256.file(packaged).hexdigest}"
queue=[[0,0]]; scheduled={[0,0]=>true}; count=0; index=0
while index<queue.length
  old_state,new_state=queue[index]; index+=1
  abort 'Unexpectedly large state graph; manual inspection required.' if queue.length>1024
  modifier_count.times do |mods|
    128.times do |key|
      source_key={10=>50,50=>10}.fetch(key,key)
      expected,old_next=kb.transition(original,source_key,mods,old_state)
      actual,new_next=kb.transition(custom,key,mods,new_state)
      unless expected==actual
        abort "FAIL: key=#{key} modifiers=#{mods} states=#{old_state}/#{new_state}: #{expected.inspect} != #{actual.inspect}"
      end
      pair=[old_next,new_next]
      unless scheduled[pair]
        scheduled[pair]=true
        queue << pair
      end
      count+=1
    end
  end
end
puts "PASS: #{count} translations across #{index} reachable state pairs."
puts "Coverage: keycodes 0-127; #{modifier_count} modifier masks; reachable accent states; key-down translation."
puts 'All compared outputs match Apple after swapping only virtual keycodes 10 and 50.'
puts 'Installed artifact matches repository artifact byte for byte.'
puts 'No installation, preference writes, source selection, or network operations performed.'
