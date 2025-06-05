package com.pfe.gestionstages.controller;

import com.pfe.gestionstages.model.Document;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.DocumentRepository;
import com.pfe.gestionstages.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
                    .utilisateur(userOpt.get())
                    .build();

            documentRepository.save(doc);

            return ResponseEntity.ok("Document déposé avec succès");

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors du dépôt : " + e.getMessage());
        }
    }

    @GetMapping("/user/{userId}")
    public List<Document> getDocumentsByUser(@PathVariable Long userId) {
        return documentRepository.findByUtilisateurId(userId);
    }
}
