# Read-only interface to macOS keyboard translation APIs. No preferences are changed.
require 'fiddle/import'

module KeyboardAPI
  extend Fiddle::Importer
  dlload '/System/Library/Frameworks/Carbon.framework/Carbon',
         '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'
  extern 'void* TISCreateInputSourceList(void*, char)'
  extern 'void* TISGetInputSourceProperty(void*, void*)'
  extern 'long CFArrayGetCount(void*)'
  extern 'void* CFArrayGetValueAtIndex(void*, long)'
  extern 'char CFStringGetCString(void*, void*, long, unsigned int)'
  extern 'void* CFDataGetBytePtr(void*)'
  extern 'unsigned int LMGetKbdType()'
  extern 'int UCKeyTranslate(void*, unsigned short, unsigned short, unsigned int, unsigned int, unsigned int, void*, unsigned long, void*, void*)'

  def self.constant(name)
    @constants ||= {}
    @constants[name] ||= Fiddle::Pointer.new(Fiddle::Pointer.new(handler.sym(name))[0,Fiddle::SIZEOF_VOIDP].unpack1('J'))
  end

  def self.property(source, name)
    TISGetInputSourceProperty(source, constant(name))
  end

  def self.string(ptr)
    return nil if ptr.null?
    buffer=Fiddle::Pointer.malloc(4096, Fiddle::RUBY_FREE)
    raise 'Cannot decode input-source property' if CFStringGetCString(ptr,buffer,4096,0x08000100)==0
    buffer.to_s.force_encoding('UTF-8')
  end

  def self.sources
    # Retain the CFArray for the lifetime of this process; its entries are borrowed.
    @source_list ||= TISCreateInputSourceList(nil,1)
    (0...CFArrayGetCount(@source_list)).map {|i| CFArrayGetValueAtIndex(@source_list,i)}
  end

  def self.id(source)
    string(property(source,'kTISPropertyInputSourceID'))
  end

  def self.data(source)
    @data ||= {}
    @data[source.to_i] ||= begin
      cfdata=property(source,'kTISPropertyUnicodeKeyLayoutData')
      raise 'Input source has no Unicode layout data' if cfdata.null?
      CFDataGetBytePtr(cfdata)
    end
  end

  def self.transition(source, key, modifiers, initial=0, type=LMGetKbdType(), options=0)
    state=Fiddle::Pointer.malloc(4, Fiddle::RUBY_FREE)
    state[0,4]=[initial].pack('L')
    length=Fiddle::Pointer.malloc(8, Fiddle::RUBY_FREE)
    length[0,8]=[0].pack('Q')
    buffer=Fiddle::Pointer.malloc(512, Fiddle::RUBY_FREE)
    status=UCKeyTranslate(data(source),key,0,modifiers,type,options,state,256,length,buffer)
    raise "UCKeyTranslate error #{status}" unless status==0
    count=length[0,8].unpack1('Q')
    raise 'Unexpected translation length' if count>256
    [buffer[0,count*2].force_encoding('UTF-16LE').encode('UTF-8'),state[0,4].unpack1('L')]
  end
end
