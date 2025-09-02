package com.pfe.gestionstages.repository;

import com.pfe.gestionstages.dto.DocumentDTO;
import com.pfe.gestionstages.model.Document;
import com.pfe.gestionstages.model.OptionParcours;
import com.pfe.gestionstages.model.Statut;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentRepository extends JpaRepository<Document, Long> {
    // --- tes méthodes existantes (garde-les si tu t’en sers ailleurs) ---
    List<Document> findByUtilisateurId(Long utilisateurId);
    Optional<Document> findTopByUtilisateurIdAndTypeOrderByDateDepotDesc(Long utilisateurId, String type);
    int countByUtilisateurIdAndType(Long userId, String type);
    List<Document> findByUtilisateurIdAndTypeStartingWithOrderByDateDepotAsc(Long userId, String typePrefix);
    List<Document> findByUtilisateurOptionParcours(OptionParcours optionParcours);
    List<Document> findByUtilisateurEmailContainingIgnoreCase(String email);
    List<Document> findByUtilisateurEmailContainingIgnoreCaseAndUtilisateurOptionParcours(
            String email, OptionParcours optionParcours);

    // --- NOUVEAU : un seul point d’entrée avec tous les filtres optionnels ---
    @Query("""
        select new com.pfe.gestionstages.dto.DocumentDTO(d)
        from Document d
        join d.utilisateur u
        where (:email is null or lower(u.email) like lower(concat('%', :email, '%')))
          and (:optionParcours is null or u.optionParcours = :optionParcours)
          and (:type is null or d.type = :type)
          and (:statut is null or d.statut = :statut)
        order by d.dateDepot desc
    """)
    List<DocumentDTO> findAllWithFilters(@Param("email") String email,
                                         @Param("optionParcours") OptionParcours optionParcours,
                                         @Param("type") String type,
                                         @Param("statut") Statut statut);
}
