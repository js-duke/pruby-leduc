default: yield

yield:
	ruby yield.rb

_default: somme_tableaux_profiles

_default: somme_tableaux_pcall_et_al

somme_tableaux_profiles:
	ruby --profile.flat somme-tableaux-profile.rb 2> profs-flat.txt
	ruby --profile.graph somme-tableaux-profile.rb 2> profs-graph.txt

pcall somme_tableaux_pcall_et_al:
	ruby somme-tableaux-pcall-peach-pmap.rb

pcall_peach:
	ruby pcall-peach.rb

clean:
	rm -f *~
