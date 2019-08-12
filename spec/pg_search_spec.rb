if Gem.loaded_specs.key?('pg_search')
  ActiveRecord::Schema.define do
    self.verbose = false

    create_table :blog_posts, force: true do |t|
      t.text :title
      t.timestamps
    end

    create_table :people, force: true do |t|
      t.string :first_name
      t.string :last_name
      t.timestamps
    end

    create_table :crackers, force: true do |t|
      t.string :kind
      t.timestamps
    end

    create_table :cheeses, force: true do |t|
      t.string :kind
      t.string :brand, default: 'Gouda'
      t.references :cracker
      t.timestamps
    end

    create_table :salamis, force: true do |t|
      t.references :cracker
      t.timestamps
    end
  end

  class BlogPost < ActiveRecord::Base
    include PgSearch
    pg_search_scope :search_by_title, against: :title
  end

  class Person < ActiveRecord::Base
    include PgSearch
    pg_search_scope :search_by_full_name, against: %i[first_name last_name]
  end

  class Cracker < ActiveRecord::Base
    has_many :cheeses
    has_one :salami
  end

  class Cheese < ActiveRecord::Base
  end

  class Salami < ActiveRecord::Base
    include PgSearch

    belongs_to :cracker
    has_many :cheeses, through: :cracker

    pg_search_scope :tasty_search, associated_against: {
      cheeses: %i[kind brand],
      cracker: :kind,
    }
  end

  describe PgSearch do
    class PgSearchMiddleware
      def self.call(arel, next_middleware)
        next_middleware.call(arel)
      end
    end

    it 'works for a simple search scope' do
      Arel.middleware.apply([PgSearchMiddleware]) do
        post1 = BlogPost.create!(title: 'Recent Developments in the World of Pastrami')
        BlogPost.create!(title: 'Prosciutto and You: A Retrospective')

        expect(BlogPost.search_by_title('pastrami').load).to eq [post1]
      end
    end

    it 'works for multiple columns' do
      Arel.middleware.apply([PgSearchMiddleware]) do
        person1 = Person.create!(first_name: 'Grant', last_name: 'Hill')
        person2 = Person.create!(first_name: 'Hugh', last_name: 'Grant')

        expect(Person.search_by_full_name('Grant')).to eq [person1, person2]
        expect(Person.search_by_full_name('Grant Hill')).to eq [person1]
      end
    end

    it 'works for searching associations' do
      Arel.middleware.apply([PgSearchMiddleware]) do
        salami1 = Salami.create!
        salami2 = Salami.create!
        salami3 = Salami.create!

        limburger = Cheese.create!(kind: 'Limburger')
        brie = Cheese.create!(kind: 'Brie')
        pepper_jack = Cheese.create!(kind: 'Pepper Jack')

        Cracker.create!(kind: 'Black Pepper', cheeses: [brie], salami: salami1)
        Cracker.create!(kind: 'Ritz', cheeses: [limburger, pepper_jack], salami: salami2)
        Cracker.create!(kind: 'Graham', cheeses: [limburger], salami: salami3)

        expect(Salami.tasty_search('pepper')).to eq [salami1, salami2]
      end
    end
  end
end
