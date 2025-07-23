package com.pfe.gestionstages.repository;

import com.pfe.gestionstages.model.Convention;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.model.StatutConvention;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConventionRepository extends JpaRepository<Convention, Long> {

    // 📌 Récupérer toutes les conventions d’un utilisateur
    List<Convention> findByEtudiantId(Long etudiantId);

    // 📌 Recherche filtrée côté admin
    List<Convention> findByStatut(StatutConvention statut);

    // 📌 Recherche par email de l'étudiant
    List<Convention> findByEtudiantEmailContainingIgnoreCase(String email);

    Convention findTopByEtudiantIdOrderByCreatedAtDesc(Long etudiantId);

}
