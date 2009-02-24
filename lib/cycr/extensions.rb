class String
  def to_cyc
    #self =~ /_missing_method_(.*)/ ? "#{$1.gsub("_","-")}" : "\"#{self}\""
    "\"#{self}\""
  end
end

class Symbol
  def to_cyc
    "#\$#{self}"
  end
end

class Array
  def to_cyc(quote = false)
    "("+map{|e| e.to_cyc}.join(" ")+")"
  end
end

class Fixnum
  def to_cyc
    to_s
  end
end

