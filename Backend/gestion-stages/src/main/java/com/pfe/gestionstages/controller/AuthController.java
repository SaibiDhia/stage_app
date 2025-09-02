package com.pfe.gestionstages.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import com.pfe.gestionstages.dto.LoginRequest;
import com.pfe.gestionstages.dto.LoginResponse;
import com.pfe.gestionstages.dto.RegisterRequest;
import com.pfe.gestionstages.model.OptionParcours;
import com.pfe.gestionstages.model.Role;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.UserRepository;
import com.pfe.gestionstages.service.JwtService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        // Email unique
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email déjà utilisé !");
        }

        // Parse option (peut être null)
        OptionParcours option = null;
        if (request.getOption() != null && !request.getOption().isBlank()) {
            try {
                option = parseOption(request.getOption());
            } catch (IllegalArgumentException ex) {
                return ResponseEntity.badRequest()
                        .body("Option inconnue: " + request.getOption());
            }
        }

        // Rôle par défaut si non fourni
        Role role = request.getRole();
        if (role == null) {
            role = Role.ETUDIANT;
        }
        // Si l’option est PROFESSEUR, on peut forcer le rôle PROFESSEUR (selon ta règle métier)
        if (option == OptionParcours.ENCADRANT) {
            role = Role.ENCADRANT;
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .optionParcours(option)
                .build();

        userRepository.save(user);

        return ResponseEntity.ok("Inscription réussie !");
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail()).orElse(null);

        if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            return ResponseEntity.status(401).body("Email ou mot de passe incorrect !");
        }

        String token = jwtService.generateToken(user.getEmail());
        // Si plus tard tu veux renvoyer aussi l’option au Front, ajoute-la dans LoginResponse.
        return ResponseEntity.ok(new LoginResponse(token, user.getRole().name(), user.getId()));
    }

    @GetMapping("/login")
    public ResponseEntity<?> fakeLogin() {
        return ResponseEntity
                .status(HttpStatus.METHOD_NOT_ALLOWED)
                .body("Ce endpoint accepte uniquement les requêtes POST.");
    }

    // --- Helpers ---

    /**
     * Normalise et convertit la chaîne d’option venant du front en enum OptionParcours.
     * Gère ERP/BI -> ERP_BI, ArcTIC -> ARCTIC, espaces, casse, accents non nécessaires ici.
     */
    private OptionParcours parseOption(String raw) {
        String n = raw.trim()
                .replace('/', '_')
                .replace(' ', '_')
                .toUpperCase();

        // Quelques alias ergonomiques :
        if (n.equals("ARCTIC") || n.equals("ARC_TIC")) n = "ARCTIC";
        if (n.equals("ERP_BI") || n.equals("ERPBI")) n = "ERP_BI";

        return OptionParcours.valueOf(n);
    }
}
