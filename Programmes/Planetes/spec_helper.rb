def assert_planete_in_delta( p1, p2 )
  assert_vector_in_delta p1.position, p2.position
  assert_vector_in_delta p1.vitesse, p2.vitesse
end

def assert_systeme_planetaire_in_delta( s1, s2 )
  assert_equal s1.planetes.size, s2.planetes.size

  s1.planetes.each_index do |k|
    assert_planete_in_delta s1[k], s2[k]
  end
end
