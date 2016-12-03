require_relative 'spec_helper'
require 'pruby'

describe PRuby do
  def run_test( source, attendu )
    yield( PRuby::Stream.source( source ) )
      .to_a
      .must_equal attendu
  end

  describe PRuby::Stream do
    describe "ops-avec-threads-multiples" do
      it "execute map avec plusieurs threads" do
        n = 1000
        a = (1..n).map { |i| i }
        r = (1..n).map { |i| 10 * i }

        PRuby::Stream.source( a )
          .map( nb_threads: 10 ) { |x| 10 * x }
          .sort
          .to_a
          .must_equal r
      end

      it "execute filter avec plusieurs threads" do
        a = (1..100).map { |i| i }
        r = a.select { |x| x.even? }

        PRuby::Stream.source( a )
          .filter( nb_threads: 4 ) { |x| x.even? }
          .sort
          .to_a
          .must_equal r
      end

      it "execute reject avec plusieurs threads" do
        a = (1..100).map { |i| i }
        r = a.select { |x| !x.even? }

        PRuby::Stream.source( a )
          .reject( nb_threads: 4 ) { |x| x.even? }
          .sort
          .to_a
          .must_equal r
      end

      it "execute peek avec plusieurs threads" do
        a = (1..100).map { |i| i }

        mutex = Mutex.new
        res = []
        PRuby::Stream.source( a )
          .peek( nb_threads: 4 ) { |x| mutex.synchronize { res << x } }
          .sort
          .to_a
          .must_equal a

        res.sort.must_equal a
      end

      it "execute uniq avec plusieurs threads" do
        n = 100
        a = (1..n).map { |i| [i, i+1, i+2] }.flatten

        mutex = Mutex.new
        PRuby::Stream.source( a )
          .uniq( nb_threads: 10 )
          .sort
          .to_a
          .must_equal ((1..n).to_a << n+1 << n+2)
      end

      it "execute flat_map avec plusieurs threads" do
        n = 74
        a = [1, 0, 2, 0, 2, 1] * n
        r = ([1, 2] * (4*n)).sort

        run_test( a, r ) do |s|
          s.flat_map( nb_threads: 4 ) { |x| x == 0 ? [] : [x, x] }
            .sort
        end
      end
    end

    describe ".source" do
      it "genere une erreur si la taille du buffer est nul ou negative" do
        lambda { PRuby::Stream.source( [], buffer_size: 0 ) }.must_raise DBC::Failure
        lambda { PRuby::Stream.source( [], buffer_size: -1 ) }.must_raise DBC::Failure
      end

      it "ne peut utiliser qu'un seul thread" do
        lambda { PRuby::Stream.source( [], nb_threads: 1 ) }.must_be_silent

        lambda { PRuby::Stream.source( [], nb_threads: 0 ) }.must_raise DBC::Failure
        lambda { PRuby::Stream.source( [], nb_threads: 2 ) }.must_raise DBC::Failure
      end

      it "retourne un Stream a partir d'un Array avec une taille explicite" do
        a = [10, 20, 30, 40]

        PRuby::Stream.source( a, buffer_size: 1 )
          .to_a
          .must_equal a
      end

      it "retourne rien si tous les elements sont nil" do
        a = [nil, nil, nil]

        PRuby::Stream.source( a )
          .to_a
          .must_equal []
      end

      it "retourne un Stream a partir d'un Array sans taille explicite" do
        a = [10, 20, 30, 40]

        PRuby::Stream.source( a )
          .to_a
          .must_equal a
      end

      it "retourne un Stream a partir d'un Hash" do
        a = {a: 10, b: 20, c: 30}
        PRuby::Stream.source( a )
          .to_a
          .must_equal [[:a, 10], [:b, 20], [:c, 30]]
      end

      it "retourne un Stream a partir d'un String indique implicitement" do
        PRuby::Stream.source( 'foo.txt' )
          .to_a
          .must_equal ['f', 'o', 'o', '.', 't', 'x', 't']
      end

      it "retourne un Stream a partir d'un String indique explicitement" do
        PRuby::Stream.source( "foo.txt", source_kind: :string )
          .to_a
          .must_equal ['f', 'o', 'o', '.', 't', 'x', 't']
      end

      it "retourne un Stream a partir d'un nom de fichier" do
        lignes = ["abc", "def", "", "."]

        fich = "foo#{$$}.txt"

        File.open( fich, "w+" ) { |f| f.puts lignes }

        PRuby::Stream.source( fich, source_kind: :filename )
          .to_a
          .must_equal lignes.map { |x| x << "\n" }

        FileUtils.rm_f fich
      end
    end

    describe ".generate-multiple-threads" do
      it "retourne un Stream vide quand tous retournent nil" do
        nb_threads = 100

        PRuby::Stream.generate(nb_threads: nb_threads) do
          nil
        end
          .to_a
          .must_equal []
      end

      it "retourne juste des 1" do
        nb_threads = 100

        PRuby::Stream.generate(nb_threads: nb_threads) do
          1
        end
          .take(nb_threads)
          .to_a
          .must_equal [1] * nb_threads
      end

      it "retourne juste des 1" do
        nb_threads = 100

        PRuby::Stream.generate(nb_threads: nb_threads) do
          1 if rand > 0.5
        end
          .to_a
          .all? { |x| x == 1}
          .must_equal true
      end

      it "retourne un Stream constant en utilisant plusieurs threads" do
        nb_threads = 5
        nb = 20
        tid = 0
        mutex = Mutex.new

        PRuby::Stream.generate(nb_threads: nb_threads) do
          unless id = Thread.current[:id]
            mutex.synchronize { Thread.current[:id] = tid; tid += 1 }
          end
          id = Thread.current[:id]
          Thread.current[:x] ||= 0
          if Thread.current[:x] == nb
            nil
          else
            x = Thread.current[:x] += 1
            1
          end
        end
          .to_a
          .must_equal [1] * (nb * nb_threads)
      end

      it "retourne un Stream constant en utilisant plusieurs threads (bis)" do
        nb = 10
        mutex = Mutex.new

        n = nb
        PRuby::Stream.generate(nb_threads: 3) do
          mutex.synchronize do
            if n == 0
              nil
            else
              n -= 1
              1
            end
          end
        end
          .to_a
          .must_equal [1] * nb
      end
    end

    describe ".generate" do
      it "retourne un Stream constant avec un nombre fixe d'elements" do
        n = 3
        PRuby::Stream.generate { if n == 0 then nil else n -= 1; 1 end }
          .to_a
          .must_equal [1, 1, 1]
      end

      it "retourne un Stream avec un nombre fixe d'elements" do
        n = 3
        PRuby::Stream.generate { if n == 0 then nil else n -= 1 end }
          .to_a
          .must_equal [2, 1, 0]
      end

      it "retourne un Stream infini d'une valeur constante" do
        PRuby::Stream.generate { 1 }
          .drop( 100 )
          .take( 3 )
          .to_a
          .must_equal [1, 1, 1]
      end

      it "retourne un Stream infini d'une valeur constante utilisee pour en generer d'autres croissante" do
        PRuby::Stream.generate { 1 }
          .stateful( initial_state: 1 ) { |s,x| [s + x, s] }
          .drop( 100 )
          .take( 3 )
          .to_a
          .must_equal [101, 102, 103]
      end

      it "retourne un Stream infini de valeurs croissantes" do
        n = 0
        PRuby::Stream.generate { n += 1 }
          .drop( 1000 )
          .take( 4 )
          .to_a
          .must_equal [1001, 1002, 1003, 1004]
      end
    end

    describe "#map" do
      it "retourne rien lorsque stream vide" do
        run_test( [],
                  [] ) do |s|
          s.map { |x| 2 * x }
        end
      end

      it "retourne le bloc applique aux elements du stream" do
        run_test( [10, 20, 30],
                  [20, 40, 60] ) do |s|
          s.map { |x| 2 * x }
        end
      end

      it "retourne rien lors tous les elements generes sont nil" do
        run_test( [10, 20, 30],
                  [] ) do |s|
          s.map { |x| nil }
        end
      end
    end

    describe "#filter" do
      it "retourne rien lorsque stream vide" do
        run_test( [], [] ) do |s|
          s.filter { |x| x.even? }
        end
      end

      it "retourne rien lorsque aucun ne satisfait" do
        run_test( [1, 2, 3, 4], [] ) do |s|
          s.filter { |x| x >= 10 }
        end
      end

      it "retourne les elements qui satisfont le bloc" do
        run_test( [1, 2, 3, 4], [2, 4] ) do |s|
          s.filter { |x| x.even? }
        end
      end

      it "retourne tous lorsque tous satisfont" do
        run_test( [1, 2, 3, 4], [1, 2, 3, 4] ) do |s|
          s.filter { |x| true }
        end
      end
    end

    describe "#reject" do
      it "retourne rien lorsque stream vide" do
        run_test( [], [] ) do |s|
          s.reject { |x| !x.even? }
        end
      end

      it "retourne rien lorsque tous satisfont le bloc" do
        run_test( [1, 2, 3, 4], [] ) do |s|
          s.reject { |x| x < 10 }
        end
      end

      it "retourne les elements qui ne satisfont pas le bloc" do
        run_test( [1, 2, 3, 4], [2, 4] ) do |s|
          s.reject { |x| !x.even? }
        end
      end

      it "retourne tous lorsqu'aucun ne satisfait" do
        run_test( [1, 2, 3, 4], [1, 2, 3, 4] ) do |s|
          s.reject { |x| nil }
        end
      end
    end

    describe "#sort" do
      it "retourne rien quand vide" do
        run_test( [], [] ) do |s|
          s.sort
        end
      end

      it "retourne les elements du stream tries" do
        a = [3, 1, 4, 2]
        run_test( a, a.sort ) do |s|
          s.sort
        end
      end

      it "retourne les elements du stream tries selon le bloc fourni" do
        a = [ [10, 10], [30, 0], [30, 30], [10, 1]]
        r = [ [30, 0], [10, 1], [10, 10], [30, 30] ]
        run_test( a, r ) do |s|
          s.sort { |x, y| x.last <=> y.last }
        end
      end
    end

    describe "#uniq" do
      it "retourne rien quand vide" do
        run_test( [], [] ) do |s|
          s.uniq
        end
      end

      it "retourne les elements avec une occurrence" do
        a = [3, 1, 4, 2, 2, 3, 1]
        r = [3, 1, 4, 2]
        run_test( a, r ) do |s|
          s.uniq
        end
      end
    end

    describe "#flat_map" do
      it "retourne rien quand vide" do
        run_test( [], [] ) do |s|
          s.flat_map { |x| [x, x] }
        end
      end

      it "aplatit d'un niveau" do
        a = [1, 2, 3, 4]
        r = [1, 1, 2, 2, 3, 3, 4, 4]
        run_test( a, r ) do |s|
          s.flat_map { |x| [x, x] }
        end
      end

      it "applatit d'un niveau et ignore les vides lorsque presents" do
        a = [1, 0, 2, 0, 3, 4, 0]
        r =[1, 1, 2, 2, 3, 3, 4, 4]
        run_test( a, r ) do |s|
          s.flat_map { |x| x == 0 ? [] : [x, x] }
        end
      end
    end

    describe "#peek" do
      it "ne modifie rien du stream mais peut avoir des effets de bord" do
        a = [1, 2, 3, 4]
        res = []
        run_test( a, a ) do |s|
          s.peek { |x| res << x }
        end

        res.must_equal [1, 2, 3, 4]
      end
    end

    describe "#take" do
      it "signale une erreur si n < 0" do
        lambda { PRuby::Stream.source([]).take(-1) }.must_raise DBC::Failure
      end

      it "retourne [] lorsque n = 0" do
        a = [1, 2, 3, 4]
        run_test( a, [] ) do |s|
          s.take 0
        end
      end

      it "retourne le nombre indique lorsque n < taille" do
        a = [1, 2, 3, 4]
        run_test( a, [1, 2] ) do |s|
          s.take 2
        end
      end

      it "retourne tout lorsque n == taille" do
        a = [1, 2, 3, 4]
        run_test( a, a ) do |s|
          s.take 4
        end
      end

      it "retourne tout lorsque n > taille" do
        a = [1, 2, 3, 4]
        run_test( a, a ) do |s|
          s.take 5
        end
      end
    end

    describe "#drop" do
      it "signale une erreur si n < 0" do
        lambda { PRuby::Stream.source([]).drop(-1) }.must_raise DBC::Failure
      end

      it "retourne tout lorsque n == 0" do
        a = [1, 2, 3, 4]
        run_test( a, a ) do |s|
          s.drop 0
        end
      end

      it "retourne le nombre indique en moins lorsque n < taille" do
        a = [1, 2, 3, 4]
        run_test( a, [3, 4] ) do |s|
          s.drop 2
        end
      end

      it "retourne [] lorsque n == taille" do
        a = [1, 2, 3, 4]
        run_test( a, [] ) do |s|
          s.drop 4
        end
      end

      it "retourne [] lorsque n > taille" do
        a = [1, 2, 3, 4]
        run_test( a, [] ) do |s|
          s.drop 5
        end
      end
    end

    describe "#take_while" do
      it "retourne les elements du debut lorsque satisfont" do
        a = [1, 2, 3, 4, 1]
        r = [1, 2]
        run_test( a, r ) do |s|
          s.take_while { |x| x <= 2 }
        end
      end

      it "retourne rien lorsque le premier ne satisfait pas" do
        a = [1, 2, 3, 4]
        r = []
        run_test( a, r ) do |s|
          s.take_while { |x| x > 3 }
        end
      end

      it "retourne tout lorsque tous satisfont" do
        a = [1, 2, 3, 4]
        run_test( a, a ) do |s|
          s.take_while { |x| true }
        end
      end
    end

    describe "#drop_while" do
      it "supprime les elements du debut satisfont" do
        a = [1, 2, 3, 4, 1]
        r = [3, 4, 1]
        run_test( a, r ) do |s|
          s.drop_while { |x| x <= 2 }
        end
      end

      it "retourne rien lorsque tous satisfont" do
        a = [1, 2, 1, 2]
        r = []
        run_test( a, r ) do |s|
          s.drop_while { |x| x <= 2 }
        end
      end

      it "retourne tous lorsque le premier ne satisfait pas" do
        a = [1, 2, 1, 2]
        run_test( a, a ) do |s|
          s.drop_while { |x| x > 3 }
        end
      end
    end

    describe "#group_by" do
      it "retourne rien quand vide" do
        run_test( [], [] ) do |s|
          s.group_by { |x| x }
        end
      end

      it "retourne des paires avec le selecteur en premiere valeur" do
        a = [["abc", 1],
             ["XXX", 2],
             ["abc", 3],
             ["XXX", 4],
             ["abc", 5],
            ]
        r = [["abc", [["abc", 1], ["abc", 3], ["abc", 5]]],
             ["XXX", [["XXX", 2], ["XXX", 4]]]]

        run_test( a, r ) do |s|
          s.group_by { |x| x.first }
        end
      end

      it "retourne des paires avec le selecteur en premiere valeur" do
        a = [["abc", 1],
             ["XXX", 2],
             ["abc", 3],
             ["XXX", 4],
             ["abc", 5],
            ]
        r = [["abc", [1, 3, 5]],
             ["XXX", [2, 4]]]

        run_test( a, r ) do |s|
          s.group_by { |x| x.first }
            .map { |p| [p.first, p.last.map(&:last)] }
        end
      end

      it "retourne des paires avec les valeurs en liste si on specifie le merger" do
        a = [["abc", 1],
             ["XXX", 2],
             ["abc", 3],
             ["XXX", 4],
             ["abc", 5],
            ]
        r = [["abc", [1, 3, 5]],
             ["XXX", [2, 4]]]

        run_test( a, r ) do |s|
          s.group_by( merge_value: ->(x){x.last} ) { |x| x.first }
        end
      end

      class Foo
        attr_reader :key, :value
        def initialize( k, v )
          @key, @value = k, v
          end
      end

      it "traite des objets sans merge_value" do
        f1 = Foo.new("abc", 1)
        f2 = Foo.new("XXX", 2)
        f3 = Foo.new("abc", 3)
        f4 = Foo.new("XXX", 4)
        f5 = Foo.new("abc", 5)

        a = [f1, f2, f3, f4, f5]
        r = [["abc", [f1, f3, f5]],
             ["XXX", [f2, f4]]]

        run_test( a, r ) do |s|
          s.group_by { |x| x.key }
        end
      end

      it "traite des objets avec merge_value" do
        f1 = Foo.new("abc", 1)
        f2 = Foo.new("XXX", 2)
        f3 = Foo.new("abc", 3)
        f4 = Foo.new("XXX", 4)
        f5 = Foo.new("abc", 5)

        a = [f1, f2, f3, f4, f5]
        r = [["abc", [1, 3, 5]],
             ["XXX", [2, 4]]]

        run_test( a, r ) do |s|
          s.group_by( merge_value: ->(x){ x.value } ) { |x| x.key }
        end
      end
    end

    describe "#group_by_key" do
      it "retourne rien quand vide" do
        run_test( [], [] ) do |s|
          s.group_by_key
        end
      end

      it "retourne des paires avec le selecteur en premiere valeur" do
        a = [["abc", 1],
             ["XXX", 2],
             ["abc", 3],
             ["XXX", 4],
             ["abc", 5],
            ]
        r = [["abc", [1, 3, 5]],
             ["XXX", [2, 4]]]

        run_test( a, r ) do |s|
          s.group_by_key
        end
      end
    end

    describe "calcul du nombre d'occurrences de mots" do
      it "traite une serie de mots et compte le nombre d'occurrences" do
        lignes = ["def abc",
                  "   ",
                  "abc def abc",
                  "def def",
                  "",
                  "xyz xyz",
                  "",
                 ]
        r = [["abc", 3], ["def", 4], ["xyz", 2]]

        run_test( lignes, r ) do |s|
          s.flat_map { |l| l.split(" ") }
            .map { |m| [m, 1] }
            .group_by { |p| p.first }
            .map { |p| [p.first, p.last.map(&:last)] }
            .map { |p| [p.first, p.last.reduce(:+)] }
            .sort
        end
      end
    end

    describe "#go" do
      let(:copier) { lambda { |cin, cout| cin.each { |x| cout << x } } }

      it "retourne rien quand vide" do
        run_test( [], [] ) do |s|
          s.go(&copier)
        end
      end

      it "prend deux elements a la fois pour en generer un seul" do
        a = [10, 20, 30, 40, 50, 60]
        r = [30, 70, 110]

        add2 = lambda do |cin, cout|
          while (v1 = cin.get) != PRuby::EOS
            v2 = cin.get
            cout << v1 + v2
          end
        end
        run_test( a, r ) do |s|
          s.go(&add2)
        end
      end

      it "remplace ** par ^" do
        as = [
              ["x", "*", "*", "*", "x", "*"],
              ["x", "*", "*", "*", "*", "x", "*", "*"],
              ["x", "*", "*", "*", "*", "x", "*", "*", "*", "x"],
             ]

        rs = [
              ["x", "^", "*", "x", "*"],
              ["x", "^", "^", "x", "^"],
              ["x", "^", "^", "x", "^", "*", "x"],
             ]

        changer_exposant = lambda do |cin, cout|
          precedent = nil
          cin.each do |c|
            if precedent == '*' && c == '*'
              precedent, c = '^', nil
            end
            cout << precedent if precedent
            precedent = c
          end
          cout << precedent if precedent
        end

        as.each_index do |i|
          run_test( as[i], rs[i] ) do |s|
            s.go(&changer_exposant)
          end
        end
      end
    end

    describe "#stateful" do
      cumul = lambda { |state, x| [state + x, [x, state+x]] }

      it "retourne chaque valeur avec le total cumulatif" do
        a = [10, 20, 30, 40]
        r = [[10, 10], [20, 30], [30, 60], [40, 100]]
        run_test( a, r ) do |s|
          s.stateful( initial_state: 0,
                      &cumul )
        end
      end

      it "retourne chaque valeur avec le total cumulatif plus l'etat comme derniere valeur" do
        a = [10, 20, 30, 40]
        r = [[10, 10], [20, 30], [30, 60], [40, 100], 100]
        run_test( a, r ) do |s|
          s.stateful( initial_state: 0,
                      at_eos: :STATE,
                      &cumul )
        end
      end

      it "retourne chaque valeur avec le total cumulatif plus la valeur indiquee" do
        a = [10, 20, 30, 40]
        r = [[10, 10], [20, 30], [30, 60], [40, 100], -99]
        run_test( a, r ) do |s|
          s.stateful( initial_state: 0,
                      at_eos: -99,
                      &cumul )
        end
      end

      it "retourne chaque valeur avec le total cumulatif puis le total" do
        a = [10, 20, 30, 40]
        r = [[10, 18], [20, 38], [30, 68], [40, 108], 108]
        run_test( a, r ) do |s|
          s.stateful( initial_state: 8,
                      at_eos: -> s { s },
                      &cumul )
        end
      end

      it "retourne la moyenne cumulative" do
        moyenne = lambda do |state, x|
          total, nb = state.first + x, state.last + 1
          [ [total, nb], total / nb ]
        end

        a = [10, 20, 30, 40]
        r = [10, 15, 20, 25, 25]
        run_test( a, r ) do |s|
          s.stateful( initial_state: [0, 0],
                      at_eos: -> state { total, nb = state; total / nb },
                      &moyenne )
        end
      end
    end

    describe "#fastflow" do
      describe "changerExposants" do
        before do
          @as = [["x", "*", "*", "*", "x", "*"],
                ["x", "*", "*", "*", "*", "x", "*", "*"],
                ["x", "*", "*", "*", "*", "x", "*", "*", "*", "x"]]

          @rs = [["x", "^", "*", "x", "*"],
                ["x", "^", "^", "x", "^"],
                ["x", "^", "^", "x", "^", "*", "x"]]
        end

        it "remplace ** par ^" do
          changer_exposant = lambda do |precedent, c|
            if precedent == '*' && c == '*'
              ['^', PRuby::GO_ON]
            else
              [c, precedent ? precedent : PRuby::GO_ON]
            end
          end

          @as.each_index do |i|
            run_test( @as[i], @rs[i] ) do |s|
              s.fastflow( stateful: true,
                          at_eos: -> state { state },
                          &changer_exposant )
            end
          end
        end

        it "remplace ** par ^ en utilisant :MANY" do
          changer_exposant = lambda do |etoile_en_attente, c|
            if c == '*'
              etoile_en_attente ? [false, '^'] : [true, PRuby::NONE]
            else
              etoile_en_attente ? [false, [PRuby::MANY, '*', c]] : [false, c]
            end
          end

          @as.each_index do |i|
          run_test( @as[i], @rs[i] ) do |s|
            s.fastflow( stateful: true,
                        initial_state: false,
                          at_eos: -> s { '*' if s },
                          &changer_exposant )
            end
          end
        end
      end

      describe "pipeline complet de Jackson" do
        it "traite correctement l'exemple des notes de cours" do
          lignes = ["abc ** dsds cssa", "ssdsx",
                    "fssfdfdfdfdfdf",   "s.s.**xtx*zy"]

          attendus = ["abc ", "^ ds", "ds c", "ssas",
                      "sdsx", "fssf", "dfdf", "dfdf",
                      "dfs.", "s.^x", "tx*z", "y"]

          depaqueter = lambda { |ligne| ligne.chars.to_a }

          changer_exposant = lambda do |precedent, c|
            if precedent == '*' && c == '*'
              ['^', PRuby::GO_ON]
            else
              [c, precedent ? precedent : PRuby::GO_ON]
            end
          end

          n = 4
          paqueter = lambda do |bloc, c|
            bloc << c
            if bloc.size == n
              ['', bloc]
            else
              [bloc, PRuby::GO_ON]
            end
          end

          run_test( lignes, attendus ) do |s|
            s.flat_map( &depaqueter )
              .fastflow( stateful: true,
                         at_eos: -> char { char },
                         &changer_exposant )
              .fastflow( stateful: '',
                         at_eos: -> bloc { bloc },
                         &paqueter )
          end
        end
      end

      describe "#fastflow -- non stateful" do
        it "saute les elements pairs" do
          a = [1, 2, 3, 4]
          r = [2, 4]
          run_test( a, r ) do |s|
            s.fastflow { |x| x.even? ? x : PRuby::GO_ON }
          end
        end
      end

      describe "#fastflow -- stateful" do
        describe "somme de deux elements consecutifs" do
          add2 = lambda { |state, x| state ? [nil, state + x] : [x, PRuby::GO_ON] }

          it "retourne le bon resultat lorsque rien a faire a la fin" do
            a = [10, 20, 30, 40]
            r = [30, 70]
            run_test( a, r ) do |s|
              s.fastflow( stateful: true, &add2 )
            end
          end

          it "retourne le bon resultat lorsqu'une valeur initiale est specifiee et rien a faire a la fin " do
            a = [10, 20, 30]
            r = [18, 50]
            run_test( a, r ) do |s|
              s.fastflow( stateful: 8, &add2 )
            end
          end

          it "retourne le bon resultat lorsque quelque chose a faire a la fin" do
            a = [10, 20, 30, 40, 50]
            r = [30, 70, 50]
            run_test( a, r ) do |s|
              s.fastflow( stateful: true,
                          initial_state: nil,
                          at_eos: -> s { s },
                          &add2 )
            end
          end
        end
      end
    end

    describe "#ff_node" do
      describe "changerExposants" do
        before do
          @as = [["x", "*", "*", "*", "x", "*"],
                ["x", "*", "*", "*", "*", "x", "*", "*"],
                ["x", "*", "*", "*", "*", "x", "*", "*", "*", "x"]]

          @rs = [["x", "^", "*", "x", "*"],
                ["x", "^", "^", "x", "^"],
                ["x", "^", "^", "x", "^", "*", "x"]]
        end

        it "remplace ** par ^" do
          changer_exposant = lambda do |precedent, c, _ff_node|
            if precedent == '*' && c == '*'
              ['^', PRuby::GO_ON]
            else
              [c, precedent ? precedent : PRuby::GO_ON]
            end
          end

          @as.each_index do |i|
            run_test( @as[i], @rs[i] ) do |s|
              s.ff_node( stateful: true,
                         at_eos: lambda { |state, _channel| state },
                         &changer_exposant )
            end
          end
        end

        it "remplace ** par ^ en utilisant le canal de sortie" do
          changer_exposant = lambda do |etoile_en_attente, c, out_channel|
            if c == '*'
              out_channel << '^' if etoile_en_attente
            else
              out_channel << '*' if etoile_en_attente
              out_channel << c
            end
            [c == '*' && !etoile_en_attente, PRuby::GO_ON]
          end

          @as.each_index do |i|
            run_test( @as[i], @rs[i] ) do |s|
              s.ff_node( stateful: true,
                         initial_state: false,
                         at_eos: lambda { |s, _channel| '*' if s },
                         &changer_exposant )
            end
          end
        end
      end

      it "fait un petit calcul du style de celui qu'on trouve dans le tutoriel" do
        generate_1_10 = lambda do |out_channel|
          (1..10).each do |k|
            out_channel << k
          end
          PRuby::EOS
        end

        res = PRuby::Stream.source([])
          .ff_node( at_eos: generate_1_10 )
          .ff_node { |x| x * 10 }
          .ff_node { |x| "Received #{x}" }
          .to_a

        res.must_equal (1..10).map { |x| "Received #{10*x}" }
      end

      it "fait un petit calcul du style de celui qu'on trouve dans le tutoriel" do
        res = PRuby::Stream.source([10])
          .ff_node { |n, out_channel| (1..n).each { |k| out_channel << k }; PRuby::EOS }
          .ff_node { |x| x * 10 }
          .ff_node { |x| "Received #{x}" }
          .to_a

        res.must_equal (1..10).map { |x| "Received #{10*x}" }
      end
    end

    describe ".iterate" do
      it "retourne le stream tel que quand on itere 0 fois" do
        a = [10, 20]
        PRuby::Stream.source( a )
          .iterate( 0 ) { |s| s.map { |x| x + 1 } }
          .to_a
          .must_equal a
      end

      it "retourne l'application le nombre de fois indique" do
        a = [10, 20]
        PRuby::Stream.source( a )
          .iterate( 3 ) { |s| s.map { |x| x + 1 } }
          .to_a
          .must_equal [13, 23]
      end

      it "retourne l'application le nombre de fois indique" do
        a = [0]

        PRuby::Stream.source( a )
          .iterate( 1 ) do |s|
          s.flat_map do |n|
            (1..(n+1)).map { |i| i }
          end
        end
          .to_a
          .must_equal [1]

        PRuby::Stream.source( a )
          .iterate( 2 ) do |s|
          s.flat_map do |n|
            (1..(n+1)).map { |i| i }
          end
        end
          .to_a
          .must_equal [1, 2]

        PRuby::Stream.source( a )
          .iterate( 3 ) do |s|
          s.flat_map do |n|
            (1..(n+1)).map { |i| i }
          end
        end
          .to_a
          .must_equal [1, 2, 1, 2, 3]

        PRuby::Stream.source( a )
          .iterate( 4 ) do |s|
          s.flat_map do |n|
            (1..(n+1)).map { |i| i }
          end
        end
          .to_a
          .must_equal [1, 2, 1, 2, 3, 1, 2, 1, 2, 3, 1, 2, 3, 4]
      end

      it "calcule pi" do
        # Exemple inspire/adapte de la documentation Flink:
        # https://ci.apache.org/projects/flink/flink-docs-master/apis/batch/index.html

        nb = 1000

        est_dans_cercle = lambda do
          x, y = rand, rand
          x*x + y*y < 1.0
        end

        PRuby::Stream.source( [0] )
          .iterate( nb ) do |s|
          s.map( nb_threads: 4 ) do |i|
            i + (est_dans_cercle.call ? 1 : 0)
          end
        end
          .map { |c| 4.0 * c / nb.to_f }
          .to_a
          .first
          .must_be_within_epsilon 3.14159, 0.1
      end
    end

    describe "#sink" do
      it "equivaut a to_a lorsqu'on indique Array" do
        a = [10, 20, 30]
        PRuby::Stream.source( a )
          .sink( Array )
          .must_equal a
      end

      it "ajoute a un tableau existant" do
        a = [10, 20, 30]
        r = [1, 2]
        PRuby::Stream.source( a )
          .sink( r )
          .must_equal [1, 2, 10, 20, 30]
      end

      it "ajoute a un fichier specifie par un String" do
        a = [10, 20, 30]

        fich = "foo0#{$$}.txt"
        PRuby::Stream.source( a )
          .sink( fich )

        IO.readlines( fich )
          .must_equal a.map { |x| "#{x}\n" }

        FileUtils.rm_f fich
      end

      it "ajoute a STDOUT" do
        a = [11, 21, 31]

        lignes_ecrites = []
        STDOUT.stub :puts, ->(l) { lignes_ecrites << l } do
          PRuby::Stream.source( a )
            .map { |x| "#{x}\n" }
            .sink( STDOUT )
        end
        lignes_ecrites.must_equal (a.map { |x| "#{x}\n" })
      end

      it "ajoute a un fichier deja ouvert qui repond a puts" do
        a = [10, 20, 30]

        fich = "foo1#{$$}.txt"
        File.open(fich, "w+") do |fd|
          PRuby::Stream.source( a )
            .map { |x | "#{x}\n" }
            .sink( fd )
        end

        IO.readlines( fich )
          .must_equal a.map { |x| "#{x}\n" }

        FileUtils.rm_f fich
      end

      it "utilise << si l'objet y repond" do
        a = [1, 2, 3]

        foo = Object.new
        def foo.<<( x )
            $res << x
        end

        $res = []
        PRuby::Stream.source( a )
            .sink( foo )

        $res.must_equal [1, 2, 3]
      end
    end

    describe "#apply" do
      it "retourne le meme stream quand on applique un bloc identite" do
        a = [1, 2, 3]

        PRuby::Stream.source( a )
          .apply { |s| s }
          .to_a
          .must_equal a
      end

      it "retourne le meme stream quand on applique un lambda identite" do
        a = [1, 2, 3]

        PRuby::Stream.source( a )
          .apply( lambda { |s| s } )
          .to_a
          .must_equal a
      end

      it "retourne le stream resultant de l'application du bloc" do
        a = [1, 2, 3]

        PRuby::Stream.source( a )
          .apply { |s| s.map { |x| x * 10 }.map { |x| x +  1 }.take(4) }
          .to_a
          .must_equal [11, 21, 31]
      end

      it "retourne le stream resultant de l'application du lambda" do
        a = [1, 2, 3]
        carre = lambda { |s| s.map { |x| x * x } }

        PRuby::Stream.source( a )
          .apply( carre )
          .to_a
          .must_equal [1, 4, 9]
      end

      it "retourne le stream resultant de l'application du lambda avec >>" do
        a = [1, 2, 3]
        carre = lambda { |s| s.map { |x| x * x } }
        plus1 = lambda { |s| s.map { |x| x + 1 } }

        s = PRuby::Stream.source( a ) >>
          carre >>
          carre >>
          plus1

        s.to_a
          .must_equal [2, 17, 82]
      end

      it "retourne le stream resultant de l'application du lambda" do
        a = [1, 2, 3]
        carre2 = lambda { |s| s.map { |x| x * x }.map { |x| x * x } }
        plus1 = lambda { |s| s.map { |x| x + 1 } }

        s = PRuby::Stream.source( a )
          .apply( carre2 )
          .apply( plus1 )

        s.to_a
          .must_equal [2, 17, 82]
      end
    end

    describe "#tee" do
      it "copie le stream d'entree sur les deux nouveaux streams" do
        s1, s2 = PRuby::Stream.source( [10, 20, 30] )
          .tee

        assert s1.kind_of?(PRuby::Stream), "s1 pas un Stream"
        assert s2.kind_of?(PRuby::Stream), "s2 pas un Stream"

        s1.map { |x| x / 10 }
          .to_a
          .must_equal [1, 2, 3]

        s2.map { |x| 2 * x }
          .to_a
          .must_equal [20, 40, 60]
      end

      it "copie le stream d'entree sur les deux nouveaux streams avec des paires" do
        s1, s2 = PRuby::Stream.source( [1, 2, 3] )
          .tee

        s1.map { |x| [x, 1] }
          .to_a
          .must_equal [[1, 1], [2, 1], [3, 1]]

        s2.map { |x| [x, x] }
          .to_a
          .must_equal [[1, 1], [2, 2], [3, 3]]
      end

      it "copie le stream d'entree sur les k streams" do
        s1, s2, s3 = PRuby::Stream.source( [10, 20, 30] )
          .tee(nb_outputs: 3)

        s1.map { |x| x / 10 }
          .to_a
          .must_equal [1, 2, 3]

        s2.map { |x| 2 * x }
          .to_a
          .must_equal [20, 40, 60]

        s3.map { |x| x + 1 }
          .to_a
          .must_equal [11, 21, 31]
      end
    end

    describe "#join" do
      it "retourne rien si aucun match" do
        PRuby::Stream.source( [[1, 2], [2, 3]] )
          .join( PRuby::Stream.source( [[3, 9]] ) )
          .to_a
          .must_equal []
      end

      it "traite le petit exemple de Spark" do
        PRuby::Stream.source( [[1, 2], [3, 4], [3, 6]] )
          .join( PRuby::Stream.source( [[3, 9]] ) )
          .to_a
          .must_equal [[3, [4, 9]], [3, [6, 9]]]
      end

      it "traite le petit exemple de Spark avec une fonction key explicite" do
        PRuby::Stream.source( [[2, 1], [4, 3], [6, 3]] )
          .join( PRuby::Stream.source( [[9, 3]] ), by_key: ->(s){ s.last } )
          .to_a
          .must_equal [[3, [[4, 3], [9, 3]]],
                       [3, [[6, 3], [9, 3]]]]
      end

      it "traite le petit exemple de Spark avec une fonction key explicite" do
        PRuby::Stream.source( [[2, 1], [4, 3], [6, 3]] )
          .join( PRuby::Stream.source( [[9, 3]] ),
                 by_key: ->(s){ s.last },
                 map_value: ->(s) { s.first } )
          .to_a
          .must_equal [[3, [4, 9]],
                       [3, [6, 9]]]
      end

      it "traite deux streams generes d'un tee" do
        # [[1, 1], [2, 1], [3, 1]]
        # [[1, 1], [2, 2], [3, 3]]

        s1, s2 = PRuby::Stream.source( [1, 2, 3] )
          .tee

        s1.flat_map { |x| [[x, 1]] }
          .join( s2.map { |x| [x, x] } )
          .to_a
          .must_equal [
                       [1, [1, 1]],
                       [2, [1, 2]],
                       [3, [1, 3]]
                      ]
      end

      it "traite deux streams generes d'un tee avec plusieurs paires" do
        # [[1, 1], [1, 1], [2, 1], [2, 2], [3, 1], [3, 3]]
        # [[1, 1], [2, 2], [3, 3]]

        s1, s2 = PRuby::Stream.source( [1, 2, 3] )
          .tee

        s1.flat_map { |x| [[x, 1], [x, x]] }
          .join( s2.map { |x| [x, x] } )
          .to_a
          .must_equal [
                       [1, [1, 1]],
                       [1, [1, 1]],
                       [2, [1, 2]],
                       [2, [2, 2]],
                       [3, [1, 3]],
                       [3, [3, 3]],
                      ]
      end
    end
  end
end

