package com.pfe.gestionstages.repository;

import com.pfe.gestionstages.model.Document;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentRepository extends JpaRepository<Document, Long> {
    List<Document> findByUtilisateurId(Long utilisateurId);
    Optional<Document> findTopByUtilisateurIdAndTypeOrderByDateDepotDesc(Long utilisateurId, String type);
    int countByUtilisateurIdAndType(Long userId, String type);
}
