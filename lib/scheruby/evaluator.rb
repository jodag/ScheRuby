class Object
  def eval!(binding = Kernel,env_frame = EnvFrame.new)
    self
  end
  
  def teval!(binding = Kernel,env_frame = EnvFrame.new, tail_call = false)
    eval!(binding, env_frame)
  end
  
end

class Symbol
  def eval!(binding = Kernel, env_frame = EnvFrame.new)
    case symbol_type
    when :local, :dotmethod
      self.equal?(:self) ? eval('self', binding ) : env_frame[self]
    when :instance
      return eval('self', binding).send(:instance_variable_get, self)
    when :const
      return Object.const_get(self)
    when :scoped_const
      # If it begins with a capital letter or colon, it's a constant or class
      # [[TODO]] Handle binding properly
      return self.to_s.split('::').reject(&:empty?).inject(Object){ |klass,part| klass.const_get(part) }
    else
      raise "Unknown symbol type #{self}"
    end  
  end
  
  def to_proc
    Proc.new{|*args| args.shift.__send__(self, *args)}
  end
  
  def symbol_type
    # The only way (short of writing a C extension) to look at a symbol's name 
    # is to use id2name, which allocates an entirely new String each time, defeating the whole point of Symbol's.
    # (to_i & 0x07 often works, but not reliably (eg on :* ), and is implementation dependent, not working at all on JRuby, so we don't use it)
    # Consequently, we cache this test, and get by with only allocating a String once per Symbol.
    return @symbol_type if @symbol_type
    
    first_char = id2name[0..0]
    if first_char == '.'
      @symbol_type = :dotmethod # Our own convention, dot indicates a Scheme reference to a Ruby method
    elsif first_char == '@'
      @symbol_type = :instance
    elsif (first_char >= 'A' && first_char <= 'Z')
      @symbol_type = :const
    elsif first_char == ':'
      @symbol_type = :scoped_const # Putting the scope into the Symbol itself is also a ScheRuby convention
    else
      @symbol_type = :local # Not always ID_LOCAL, but for our purposes, it should be treated accordingly
    end
    
    return @symbol_type
    
  end
  
end

class ScheRuby::Cons
  def teval!(binding = ScheRuby, env_frame = EnvFrame.new, tail_call = false)
    case car
      #R5RS:  <syntactic keyword> --> <expression keyword>
      #R5RS:       | else | => | define 
      #R5RS:       | unquote | unquote-splicing
      #R5RS:  <expression keyword> --> quote | lambda | if
      #R5RS:       | set! | begin | cond | and | or | case
      #R5RS:       | let | let* | letrec | do | delay
      #R5RS:       | quasiquote
      #R5RS:  
      #R5RS:  `<variable> => <'any <identifier> that isn't
      #R5RS:                  also a <syntactic keyword>>
      #R5RS:  
      
    when :if
      #    Consider splitting into compiler (to Proc) / evaluator.
      #    Compiler would be:
      #    condition = cdr.car.compile!
      #    etc
      #    Proc.new do 
      #      condition.eval! ? clause.eval! : alternate.eval!
      #    end
      
      condition = cdr.car.eval!(binding, env_frame)
      if condition # Note that according to R5RS, '() is true
        cdr.cdr.car.teval!(binding, env_frame, tail_call)
      else
        alternate_clause = cdr.cdr.cdr
        # Scheme allows for missing alternate clauses, so we need to check for that
        #R5RS: If <test> yields a false value and no <alternate> is specified, 
        #R5RS: then the result of the expression is unspecified.
        alternate_clause.null? ? nil : alternate_clause.car.teval!(binding, env_frame, tail_call)
      end
      
    when :begin
      return cdr.evaleteach!(binding, env_frame)
      
    when :cond
      cdr.each do |clause|
        if (clause.car == :else) || (clause.car.eval!(binding, env_frame))
          return clause.cdr.evaleteach!(binding, env_frame)
        end
      end
      
      #R5RS: If all <test>s evaluate to false values, and there is no else clause, 
      #R5RS: then the result of the conditional expression is unspecified
      return nil
      
    when :lambda
      # We need to explicitly refer to the Cons (self), 
      # so that if this lambda (block) is attached as a method to a class, 
      # we still have a reference to the Cons expression
      this_expression = self
      return Proc.new do |*args| 
        child_env_frame = env_frame.make_child
        i = 0
        this_expression.cdr.car.each { |param| child_env_frame[param] = args[i]; i+=1 }
        this_expression.cdr.cdr.evaleteach!(this_expression == self ? binding : send(:binding), child_env_frame)
      end
      
      
    when :quote
      cdr.car

            
    when :let
      # (let ((x 3) (y 2)) x (+ x (* 2 y))) 
      # --> ((lambda (x y) x (+ x (* 2 y))) 3 2)    
      bndngs = cdr.car
      #      params = Cons.list(* bndngs.map(&:car))
      params = bndngs.listmap(proc(&:car))
      #      vals = Cons.list( * bndngs.map(&:cdr).map(&:car))
      vals = bndngs.listmap(proc {|el| el.cdr.car} )
      body_exps = cdr.cdr
      lambda_exp = Cons.append(Cons.list(:lambda, params), body_exps)
      let_exp = Cons.list(lambda_exp)
      vals.each { |val| let_exp = Cons.adjoin!(let_exp, val)}
      let_exp.eval!(binding, env_frame)
      
    when :define
      case cdr.car
      when Symbol
        env_frame[cdr.car] = cdr.cdr.car.eval!(binding, env_frame)
      when Cons
        lambda_proc_list = Cons.list(:lambda, cdr.car.cdr)
        cdr.cdr.each { |el| lambda_proc_list = Cons.adjoin!(lambda_proc_list,el) }
        Cons.list(:define, cdr.car.car, lambda_proc_list).eval!(binding, env_frame)
      else
        raise "Can't define a #{cdr.car.inspect}"
      end
      return nil
      
    when :defconstant
      eval('self', binding).const_set(cdr.car, cdr.cdr.car.eval!(binding, env_frame))     
      
    when :set!
      sym = cdr.car
      env_frame.set!(sym, cdr.cdr.car.eval!(binding, env_frame))
      
    when :'set-ivar!'
      sym = cdr.car
      eval('self', binding).send(:instance_variable_set,sym, cdr.cdr.car.eval!(binding, env_frame))
      
    when :time
      # Very rough
      start_time = Time.now
      ret_val = cdr.evaleach!(binding, env_frame)
      end_time = Time.now
      puts "#{end_time - start_time} sec\n"
      return ret_val
      
    else
      # Consider compiling:
      # params = cdr.map { |expression| expression.compile! }
      # Proc.new do
      #  procedure.eval!.call(* params.map(&:eval!) )
      # end
      
      # We're not a special form, so we apply the procedure call
      if tail_call
        return prepare(binding, env_frame)
      else
        procedure = car.eval!(binding, env_frame)
        procedure.call(* cdr.map{ |el| el.eval!(binding, env_frame)} )
      end
      
    end
  end
  
  def eval!(binding = ScheRuby, env_frame = EnvFrame.new)
    #puts inspect
    retval = teval!(binding, env_frame)
    while retval.kind_of?(InvocationInstruction)
      retval = retval.invoke!
    end
    return retval
  end
  
  def prepare(binding, env_frame)
    InvocationInstruction.new(map { |el| el.eval!(binding, env_frame)})
  end
  
  def evaleach!(binding = ScheRuby, env_frame = EnvFrame.new)
    current = self
    while ! current.cdr.null?
      current.car.eval!(binding, env_frame)
      current = current.cdr
    end
    current.car.eval!(binding, env_frame)
  end
  
  def evaleteach!(binding = ScheRuby, env_frame = EnvFrame.new)
    # PERFROMANCE Inline the eteach calls and drop the lambda
    #eteach(lambda { |el| el.eval!(binding, env_frame) }, lambda  { |el| el.teval!(binding, env_frame) })
    current = self
    while ! current.cdr.null?
      current.car.eval!(binding, env_frame)
      current = current.cdr
    end
    current.car.teval!(binding, env_frame, true)
  end
  
end # class ScheRuby::Cons

class ScheRuby::InvocationInstruction
  def initialize(arr = [])
    @arr = arr
  end
  
  def invoke!
    @arr.first.call(* @arr[1..-1] )
  end
end
