package com.pfe.gestionstages.controller;

import com.pfe.gestionstages.model.Document;
import com.pfe.gestionstages.model.Statut;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.DocumentRepository;
import com.pfe.gestionstages.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentRepository documentRepository;
    private final UserRepository userRepository;

    private final Path rootLocation = Paths.get("uploads");

    private boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof User user) {
            return user.getRole().name().equals("ADMIN");
        }
        return false;
    }

    @PostMapping("/upload")
    public ResponseEntity<?> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") String type,
            @RequestParam("userId") Long userId) {

        try {
            if (!Files.exists(rootLocation)) {
                Files.createDirectories(rootLocation);
            }

            String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path filePath = rootLocation.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

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
    public ResponseEntity<?> getAllDocuments() {
        if (!isAdmin()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé : admin uniquement.");
        }

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

        return ResponseEntity.ok("En attente");
    }

    @PutMapping("/{id}/valider")
    public ResponseEntity<?> validerDocument(@PathVariable Long id) {
        if (!isAdmin()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé : admin uniquement.");
        }

        return documentRepository.findById(id).map(doc -> {
            doc.setStatut(Statut.VALIDE);
            documentRepository.save(doc);
            return ResponseEntity.ok("Document validé");
        }).orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).body("Document non trouvé"));
    }

    @PutMapping("/{id}/rejeter")
    public ResponseEntity<?> rejeterDocument(@PathVariable Long id) {
        if (!isAdmin()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé : admin uniquement.");
        }

        return documentRepository.findById(id).map(doc -> {
            doc.setStatut(Statut.REJETE);
            documentRepository.save(doc);
            return ResponseEntity.ok("Document rejeté");
        }).orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).body("Document non trouvé"));
    }
}
