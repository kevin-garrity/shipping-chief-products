require 'lib/webify/hash_expand'
describe "Hash#expand" do
  subject { in_hash.expand }
  context "nothing to expand" do
    let(:in_hash){
        {a: 'this is a', b: 'this is b'}.stringify_keys
    }
    it "returns a 1 element array which is the original hash" do
      expect(subject).to eq([in_hash])
    end
  end

  context "all elements are arrays" do
    let(:in_hash){
        {a: ['first a', 'second a', 'third a'], b: ['first b', 'second b', 'third b']}.stringify_keys
    }

    it "returns an array of hashes where each value is the corresponding value[x] in the in hash" do
      expect(subject).to eq(
        [
          {'a' => 'first a', 'b' => 'first b'},
          {'a' => 'second a', 'b' => 'second b'},
          {'a' => 'third a', 'b' => 'third b'}
        ]
      )
    end
  end

  context "some elements are arrays" do
    let(:in_hash){
        {a: "only one a", b: ['first b', 'second b', 'third b'], c: "only one c", d: ['first d', 'second d', 'third d'] }.stringify_keys
    }
    it "returns an array of hashes where each value is the corresponding value[x] in the in hash or the scalar value" do
      expect(subject).to eq(
        [
          {'a' => 'only one a', 'b' => 'first b', 'c' => 'only one c', 'd' => 'first d'},
          {'a' => 'only one a', 'b' => 'second b', 'c' => 'only one c', 'd' => 'second d'},
          {'a' => 'only one a', 'b' => 'third b', 'c' => 'only one c', 'd' => 'third d'}
        ]
      )
    end
  end

  context "not all arary elements are same length" do
    let(:in_hash){
        {a: "only one a", b: ['first b', 'second b'], c: "only one c", d: ['first d', 'second d', 'third d'] }.stringify_keys
    }
    it "returns an array of hashes where each value is the corresponding value[x] in the in hash or nil" do
      expect(subject).to eq(
        [
          {'a' => 'only one a', 'b' => 'first b', 'c' => 'only one c', 'd' => 'first d'},
          {'a' => 'only one a', 'b' => 'second b', 'c' => 'only one c', 'd' => 'second d'},
          {'a' => 'only one a', 'b' => nil, 'c' => 'only one c', 'd' => 'third d'}
        ]
      )
    end
  end


end