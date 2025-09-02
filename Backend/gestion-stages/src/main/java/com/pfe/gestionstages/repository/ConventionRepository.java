package com.pfe.gestionstages.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.pfe.gestionstages.dto.ConventionDTO;
import com.pfe.gestionstages.model.Convention;
import com.pfe.gestionstages.model.OptionParcours;
import com.pfe.gestionstages.model.StatutConvention;

@Repository
public interface ConventionRepository extends JpaRepository<Convention, Long> {

    // 📌 Récupérer toutes les conventions d’un utilisateur
    List<Convention> findByEtudiantId(Long etudiantId);

    // 📌 Recherche filtrée côté admin
    List<Convention> findByStatut(StatutConvention statut);

    // 📌 Recherche par email de l'étudiant
    List<Convention> findByEtudiantEmailContainingIgnoreCase(String email);

    Convention findTopByEtudiantIdOrderByCreatedAtDesc(Long etudiantId);

    // 📌 Filtre par option
    List<Convention> findByEtudiant_OptionParcours(OptionParcours optionParcours);

    // 📌 Filtre combiné email + option
    List<Convention> findByEtudiantEmailContainingIgnoreCaseAndEtudiant_OptionParcours(
            String email, OptionParcours optionParcours);

@Query("""
        select new com.pfe.gestionstages.dto.ConventionDTO(c)
        from Convention c
        join c.etudiant u
        where (:email is null or lower(u.email) like lower(concat('%', :email, '%')))
          and (:optionParcours is null or u.optionParcours = :optionParcours)
          and (:statut is null or c.statut = :statut)
        order by c.createdAt desc
    """)
    List<ConventionDTO> findAllWithFilters(
            @Param("email") String email,
            @Param("optionParcours") OptionParcours optionParcours,
            @Param("statut") StatutConvention statut
    );
    

}
