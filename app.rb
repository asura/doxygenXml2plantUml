#!/usr/bin/env ruby
require 'happymapper'
require 'pp'

exit -1 unless ARGV.size == 1

# HappyMapperのParse結果をPlantUMLのクラス図記述に変換する
class Converter
  def initialize(doc)
    @doc = doc
  end

  def convert
    puts '@startuml'

    convert_class

    # 継承関係の変換
    convert_inheritance

    puts '@enduml'
  end

  private

  def cut_quote(text)
    text.gsub(/^"|"$/, '')
  end

  def convert_class
    @target_class_name = cut_quote(@doc.compounddef.compoundname)
    puts "class #{@target_class_name} {"

    @doc.compounddef.sectiondef.each do |section|
      section.memberdef.each do |member|
        convert_member(member)
      end
    end

    puts "}"
  end

  def convert_member(member)
    case member.prot
    when 'private'
      s = '-'
    when 'public'
      s = '+'
    when 'protected'
      s = '#'
    else
      raise "未対応#{member.prot}"
    end

    case member.kind
    when 'variable'
      puts "  #{s} #{convert_virtual(member.virt)}#{convert_static(member.static)}#{member.type} #{member.name}"
    when 'function'
      # puts "  #{s} #{convert_virtual(member.virt)}#{convert_static(member.static)}#{convert_function_return(member.type)}#{member.name}#{convert_function_parameter(member.param)}#{convert_function_constness(member)}"
      # puts "  #{s} #{convert_virtual(member.virt)}#{convert_static(member.static)}#{convert_function_return(member.type)}#{member.name}#{(member.argsstring)}#{convert_function_constness(member)}
      puts "  #{s} #{convert_virtual(member.virt)}#{convert_static(member.static)}#{convert_function_return(member.type)}#{member.name}#{(member.argsstring)}"
    else
      raise "未対応 #{member}"
    end
  end

  def convert_static(static)
    return '' unless static == 'yes'
    '{static} '
  end

  def convert_virtual(virtual)
    return '' unless virtual == 'yes'
    '{abstract} '
  end

  def convert_type(type)
    return '' if type.nil?
    return type if type.class.name == 'String'
    result = ''
    if type.respond_to?(:content)
      result += type.content unless type.content.nil?
    end
    if type.respond_to?(:ref)
      result += type.ref.content unless type.ref.nil?
    end
    result
  end

  def convert_function_return(type)
    result = convert_type(type)
    result += ' ' unless result.empty?
    result
  end

  def convert_function_parameter(param)
    return '()' if param.nil?
    result = '('

    if param.class.name == 'Array'
      result += param.map { |par| convert_type(par.type)}.join(',')
    else
      result += convert_type(param.type)
    end
    result += ')'
    result
  end

  def convert_function_constness(member)
    member.const == 'yes' ? ' const' : ''
  end

  def convert_inheritance
    return if @doc.compounddef.basecompoundref.nil?

    puts ''
    @base_class_name = @doc.compounddef.basecompoundref.content
    puts "#{@base_class_name} <|-- #{@target_class_name}"
  end
end

# read a xml file
file_content = nil
begin
  File.open(ARGV[0]) do |file|
    file_content = file.read
  end
rescue
  puts '例外発生'
  exit -2
end

# parse that file
doc = HappyMapper.parse(file_content)

converter = Converter.new(doc)
converter.convert
