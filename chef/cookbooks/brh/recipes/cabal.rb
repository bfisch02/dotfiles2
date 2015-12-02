include_recipe 'cabal'

cabal_update 'brh'

cabal_install 'hoogle' do
    user 'brh'
    force_reinstalls true
end

cabal_install 'pandoc' do
    user 'brh'
    force_reinstalls true
end

cabal_install 'hunit' do
    user 'brh'
    force_reinstalls true
end
