package com.pfe.gestionstages.controller;

import com.pfe.gestionstages.dto.ConventionDTO;
import com.pfe.gestionstages.model.Convention;
import com.pfe.gestionstages.model.StatutConvention;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.ConventionRepository;
import com.pfe.gestionstages.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.*;
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
@RequestMapping("/api/convention")
@RequiredArgsConstructor
public class ConventionController {

    private final ConventionRepository conventionRepository;
    private final UserRepository userRepository;

    private final Path rootDir = Paths.get("conventions");

    private boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getPrincipal() instanceof User user && user.getRole().name().equals("ADMIN");
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof User user) {
            return user;
        }
        return null;
    }

    // 1️⃣ Étudiant demande une convention
    @PostMapping("/demander")
    public ResponseEntity<?> demanderConvention(@RequestBody Convention convention) {
        User current = getCurrentUser();
        if (current == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Non authentifié");

        convention.setEtudiant(current);
        convention.setStatut(StatutConvention.EN_ATTENTE);
        conventionRepository.save(convention);
        return ResponseEntity.ok("📄 Demande de convention enregistrée.");
    }

    // 2️⃣ Voir les conventions d’un étudiant
    @GetMapping("/by-user/{id}")
    public ResponseEntity<?> getByUser(@PathVariable Long id) {
        List<Convention> list = conventionRepository.findByEtudiantId(id);
        return ResponseEntity.ok(list);
    }

    // 3️⃣ Voir toutes les conventions (admin)
   @GetMapping("/all")
public ResponseEntity<?> getAll(@RequestParam(required = false) String email) {
    if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

    List<Convention> result = (email != null && !email.isBlank())
            ? conventionRepository.findByEtudiantEmailContainingIgnoreCase(email)
            : conventionRepository.findAll();

    List<ConventionDTO> dtoList = result.stream().map(ConventionDTO::new).toList();
    return ResponseEntity.ok(dtoList);
}

    // 4️⃣ Valider la convention
    @PutMapping("/{id}/valider")
    public ResponseEntity<?> valider(@PathVariable Long id) {
        if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

        return conventionRepository.findById(id).map(conv -> {
            conv.setStatut(StatutConvention.VALIDEE);
            conventionRepository.save(conv);
            return ResponseEntity.ok("✅ Convention validée");
        }).orElse(ResponseEntity.notFound().build());
    }

    // 5️⃣ Rejeter la convention
    @PutMapping("/{id}/rejeter")
    public ResponseEntity<?> rejeter(@PathVariable Long id) {
        if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

        return conventionRepository.findById(id).map(conv -> {
            conv.setStatut(StatutConvention.REJETEE);
            conventionRepository.save(conv);
            return ResponseEntity.ok("❌ Convention rejetée");
        }).orElse(ResponseEntity.notFound().build());
    }

    // 🔟 Endpoint pour récupérer la dernière convention de l’étudiant connecté
@GetMapping("/ma-convention")
public ResponseEntity<?> getMaConvention() {
    User current = getCurrentUser();
    if (current == null) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Non authentifié");
    }

    Convention convention = conventionRepository.findTopByEtudiantIdOrderByCreatedAtDesc(current.getId());

    if (convention == null) {
        return ResponseEntity.ok().body(null); // Aucun enregistrement trouvé
    }

    return ResponseEntity.ok(convention);
}


    // 6️⃣ Upload du fichier de convention préparé (admin)
    @PostMapping("/{id}/upload-admin")
public ResponseEntity<?> uploadAdmin(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
    if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

    try {
        Files.createDirectories(rootDir);
        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path path = rootDir.resolve(filename);
        Files.copy(file.getInputStream(), path, StandardCopyOption.REPLACE_EXISTING);

        return conventionRepository.findById(id).map(conv -> {
            conv.setCheminConventionAdmin(filename); // <-- ✅ juste le nom
            conventionRepository.save(conv);
            return ResponseEntity.ok("✅ Fichier uploadé");
        }).orElse(ResponseEntity.notFound().build());

    } catch (IOException e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur : " + e.getMessage());
    }
}

    // 7️⃣ Étudiant dépose la convention signée
    @PostMapping("/{id}/upload-signee")
    public ResponseEntity<?> uploadSignee(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
        System.out.println(">>> Appel endpoint uploadSignee() OK !");
        User current = getCurrentUser();
        if (current == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Non authentifié");

        try {
            Files.createDirectories(rootDir);
            String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path path = rootDir.resolve(filename);
            Files.copy(file.getInputStream(), path, StandardCopyOption.REPLACE_EXISTING);

            return conventionRepository.findById(id).map(conv -> {
                if (!conv.getEtudiant().getId().equals(current.getId())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
                }
                conv.setCheminConventionSignee(filename);
                conv.setStatut(StatutConvention.SIGNEE_EN_ATTENTE_VALIDATION);
                conventionRepository.save(conv);
                return ResponseEntity.ok("📎 Convention signée déposée");
            }).orElse(ResponseEntity.notFound().build());

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur : " + e.getMessage());
        }
    }

    // 8️⃣ Télécharger la convention (admin → étudiant)
    @GetMapping("/{id}/download-admin")
    public ResponseEntity<?> downloadAdmin(@PathVariable Long id) {
        User current = getCurrentUser();
        if (current == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Non authentifié");

        return conventionRepository.findById(id).map(conv -> {
            if (!conv.getEtudiant().getId().equals(current.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
            }
            return serveFile(conv.getCheminConventionAdmin());
        }).orElse(ResponseEntity.notFound().build());
    }

    // 9️⃣ Télécharger la convention signée (admin)
    @GetMapping("/{id}/download-signee")
    public ResponseEntity<?> downloadSignee(@PathVariable Long id) {
        if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

        return conventionRepository.findById(id).map(conv -> serveFile(conv.getCheminConventionSignee()))
                .orElse(ResponseEntity.notFound().build());
    }

    // Méthode utilitaire pour servir un fichier
    private ResponseEntity<?> serveFile(String chemin) {
    try {
        Path path = rootDir.resolve(chemin); // <- Reconstruit depuis le nom de fichier
        Resource file = new UrlResource(path.toUri());
        if (file.exists()) {
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + path.getFileName() + "\"")
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(file);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Fichier introuvable");
        }
    } catch (Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur : " + e.getMessage());
    }
}

    @GetMapping("/by-user/{id}/latest-status")
public ResponseEntity<?> getLatestConventionStatus(@PathVariable Long id) {
    Convention latestConvention = conventionRepository
        .findTopByEtudiantIdOrderByCreatedAtDesc(id);

    if (latestConvention == null) {
        return ResponseEntity.ok("AUCUNE");
    }

    if (latestConvention.getStatut() == StatutConvention.SIGNEE_VALIDEE) {
        return ResponseEntity.ok("OK");
    }

    return ResponseEntity.ok("BLOQUE");
}

@PutMapping("/{id}/valider-signee")
public ResponseEntity<?> validerSignee(@PathVariable Long id) {
    if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

    return conventionRepository.findById(id).map(conv -> {
        conv.setStatut(StatutConvention.SIGNEE_VALIDEE);
        conventionRepository.save(conv);
        return ResponseEntity.ok("✅ Convention signée validée");
    }).orElse(ResponseEntity.notFound().build());
}

@PutMapping("/{id}/rejeter-signee")
public ResponseEntity<?> rejeterSignee(@PathVariable Long id) {
    if (!isAdmin()) return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");

    return conventionRepository.findById(id).map(conv -> {
        conv.setStatut(StatutConvention.SIGNEE_REJETEE);
        conventionRepository.save(conv);
        return ResponseEntity.ok("❌ Convention signée rejetée");
    }).orElse(ResponseEntity.notFound().build());
}


}
