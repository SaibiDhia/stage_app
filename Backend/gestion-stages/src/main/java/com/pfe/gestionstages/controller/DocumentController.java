package com.pfe.gestionstages.controller;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.pfe.gestionstages.model.Document;
import com.pfe.gestionstages.model.Statut;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.DocumentRepository;
import com.pfe.gestionstages.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentRepository documentRepository;
    private final UserRepository userRepository;

    private final Path rootLocation = Paths.get("uploads");

    @PostMapping("/upload")
    public ResponseEntity<?> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") String type,
            @RequestParam("userId") Long userId) {

        try {
            // Créer dossier s’il n’existe pas
            if (!Files.exists(rootLocation)) {
                Files.createDirectories(rootLocation);
            }

            // Sauvegarde fichier local
            String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path filePath = rootLocation.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Enregistrement DB
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) return ResponseEntity.badRequest().body("Utilisateur non trouvé");

            Document doc = Document.builder()
                    .nomFichier(filename)
                    .type(type)
                    .cheminFichier(filePath.toString())
                    .dateDepot(LocalDate.now())
                    .statut(Statut.EN_ATTENTE)
                    .utilisateur(userOpt.get())
                    .build();

            documentRepository.save(doc);

            return ResponseEntity.ok("Document déposé avec succès");

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors du dépôt : " + e.getMessage());
        }
    }

    @GetMapping("/all")
public ResponseEntity<List<Document>> getAllDocuments() {
    List<Document> documents = documentRepository.findAll();
    return ResponseEntity.ok(documents);
}

    @GetMapping("/user/{userId}")
    public List<Document> getDocumentsByUser(@PathVariable Long userId) {
        return documentRepository.findByUtilisateurId(userId);
    }

@GetMapping("/statut")
public ResponseEntity<String> getStatut(
    @RequestParam Long userId,
    @RequestParam String type) {

    Optional<Document> docOpt = documentRepository
        .findTopByUtilisateurIdAndTypeOrderByDateDepotDesc(userId, type);

    if (docOpt.isEmpty()) {
        return ResponseEntity.ok("Non encore déposé");
    }

    // tu peux changer ça plus tard si tu ajoutes une colonne "statut" à Document
    return ResponseEntity.ok("En attente");
}

@PutMapping("/{id}/valider")
public ResponseEntity<?> validerDocument(@PathVariable Long id) {
    return documentRepository.findById(id).map(doc -> {
        doc.setStatut(Statut.VALIDE);
        documentRepository.save(doc);
        return ResponseEntity.ok("Document validé");
    }).orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).body("Document non trouvé"));
}

@PutMapping("/{id}/rejeter")
public ResponseEntity<?> rejeterDocument(@PathVariable Long id) {
    return documentRepository.findById(id).map(doc -> {
        doc.setStatut(Statut.REJETE);
        documentRepository.save(doc);
        return ResponseEntity.ok("Document rejeté");
    }).orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).body("Document non trouvé"));
}



}
