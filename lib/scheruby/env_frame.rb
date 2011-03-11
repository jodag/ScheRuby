require 'singleton'

module ScheRuby

  class EnvFrame < Hash
    
    def initialize(parent = defined?(DEFAULT_ENV_FRAME) ? DEFAULT_ENV_FRAME : nil )
      super()
      @parent = parent
    end
    
    def make_child
      return EnvFrame.new(self)
    end
    
    def [](symbol)
      raise ArgumentError, "#{symbol.inspect} must be a Symbol" unless symbol.kind_of?(Symbol)
      if has_key?(symbol)
        super(symbol)
      else
        return @parent[symbol]
      end
    end
    
    def []=(symbol, value)
      raise ArgumentError, "#{symbol.inspect} must be a Symbol" unless symbol.kind_of?(Symbol)
      super(symbol, value)
    end
   
   def has_definition?(symbol)
     # We can't do [symbol] && true, since [symbol] may be false or nil
     begin
       [symbol]
       return true
     rescue
       return false
     end
   end

   def set!(symbol, value)
     raise "set!: Only a symbol can be set!, not a #{symbol.class} (#{symbol.inspect})" unless symbol.kind_of?(Symbol)
     raise "set!: Only a symbol which is already defined can be set! (#{symbol.inspect})" unless has_definition?(symbol)
     # R5RS: The resulting value is stored in the location to which <variable> is bound.
     # 
     # So, we need to find the env_frame where symbol is defined, and modify it there.
     defining_frame = self
     while !(defining_frame.has_key?(symbol))
       defining_frame = defining_frame.parent
     end
     defining_frame[symbol] = value
   end
   
   def defined_symbols
     @parent ? keys + @parent.defined_symbols : keys
   end
   
    protected
    attr_reader :parent
    
  end
  
  class DefaultEnvFrame < EnvFrame
    include Singleton
    
    def initialize
      super() { |h,k| raise ArgumentError, "#{k.inspect} is not defined in this EnvFrame" }
      @parent = nil
      
      self[:+] = Proc.new { |*args| args.inject { |acc, n| acc + n }}
      self[:*] = Proc.new { |*args| args.inject { |acc, n| acc * n }}
      self[:-] = Proc.new { |*args| args.inject { |acc, n| acc - n }}
      self[:/] = Proc.new { |*args| args.inject { |acc, n| acc.quo(n) }}
           
      self[:<] = Proc.new { |*args| args.inject { |acc, n| acc < n }}
      self[:<=] = Proc.new { |*args| args.inject { |acc, n| acc <= n }}
      self[:>] = Proc.new { |*args| args.inject { |acc, n| acc > n }}
      self[:>=] = Proc.new { |*args| args.inject { |acc, n| acc >= n }}
      
      self[:not] = Proc.new { |arg| ! arg }
       # [[BUG]] Does not shortcut properly - eg: (and #f (noproc))
      self[:and] = Proc.new { |*args| args.all? }
      self[:or] = Proc.new { |*args| args.any? }
        
      self['='.to_sym] = Proc.new { |*args| args[1..-1].all? {|arg| arg == args[0] }}
    
      # Not part of R5RS, but used in the initial SCIP chapters.
      # Not to be confused with Ruby's +nil+, represented as #nil literal
      self[:nil] = Cons::EMPTY_LIST 
    
      make_forwarding_proc(:new, :inspect, :car, :cdr, :abs, :null?, :pair?, :atom?, :list?, 'set-car!'.to_sym, 'set-cdr!'.to_sym, :modulo, :remainder)
      self[:quotient] = Proc.new { |*args| args[0].send(:div, *args[1..-1])}
      make_cons_proc(:cons, :list, :append)
      
      self[:display] = Proc.new { |arg| STDOUT.puts arg.to_s}
      self[:newline] = Proc.new { STDOUT.puts "\n"}
      
      self[:defmethod] = Proc.new { |klass, method_name, block | klass.send(:define_method,method_name, block) }
      
      self[:'hash-get'] = Proc.new { |*args| args[0].send(:[], *args[1..-1])}
      self[:'hash-set!'] = Proc.new { |*args| args[0].send(:[]=, *args[1..-1])}
      
      self[:'make-vector'] = Proc.new { |size, default_val | Array.new(size, default_val = nil) }
      self[:vector] = Proc.new { |*args| args }
      make_alias_proc :'vector-ref', :[]
      make_alias_proc :'vector-set!', :[]=
      make_alias_proc :'vector-length', :length
      make_alias_proc :'list->vector', :to_a
      make_alias_proc :'number->string', :to_s
      make_alias_proc :'string-length', :length
      make_alias_proc :map, :listmap
    end
  
    def [](symbol)
      raise ArgumentError, "#{symbol.inspect} must be a Symbol" unless symbol.kind_of?(Symbol)
      if has_key?(symbol)
        super(symbol)
      elsif symbol.symbol_type == :dotmethod
        # Create a send_proc, and cache it for this symbol
        return (self[symbol] = make_send_proc(symbol.to_s[1..-1]))
      else
        raise ArgumentError, "#{symbol.inspect} is not defined in this EnvFrame"
      end
    end
  
  private
    
    # For each +sym+, creates a procedure in the default environment by that name, 
    # which sends +sym+ to the first arg.  Any other args are sent as parameters.
    # 
    # Example:
    #  make_forwarding_proc(:car) # => (car '(3 4)) ---> '(3 4).car
    def make_forwarding_proc(*syms)
      syms.each do |sym|
        self[sym] = Proc.new { |*args|  args[0].send(sym, *args[1..-1]) }
      end
    end
    
    def make_alias_proc(scheme_name, ruby_method)
      self[scheme_name] =  Proc.new { |*args| args[0].send(ruby_method, *args[1..-1])}
    end
    
    # For each +sym+, creates a procedure in the default environment by that name, 
    # which invokes Cons.sym.  Any other args are sent as parameters.
    # 
    # Example:
    #  make_cons_proc(:cons) # => (cons 3 4) ---> Cons.cons(3,4)
    def make_cons_proc(*syms)
       syms.each do |sym|
        self[sym] = Proc.new { |*args|  Cons.send(sym, *args) }
      end
    end
  
    def make_send_proc(symbol)
      return Proc.new do |*args| 
        if args[0].respond_to?(symbol)
          args[0].send(symbol, *args[1..-1])
        else
          # Allow dashes in Scheme as replacements for Ruby's underscores
          args[0].send(symbol.gsub(/-/,'_'), *args[1..-1])
        end
      end
    end
    
    
  end

  class EnvFrame
  
    DEFAULT_ENV_FRAME = DefaultEnvFrame.instance

  end
  
end
