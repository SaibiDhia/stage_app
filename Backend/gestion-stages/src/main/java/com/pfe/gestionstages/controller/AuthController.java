package com.pfe.gestionstages.controller;

import com.pfe.gestionstages.dto.LoginRequest;
import com.pfe.gestionstages.dto.LoginResponse;
import com.pfe.gestionstages.dto.RegisterRequest;
import com.pfe.gestionstages.model.User;
import com.pfe.gestionstages.repository.UserRepository;
import com.pfe.gestionstages.service.JwtService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email déjà utilisé !");
        }

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .build();

        userRepository.save(user);

        return ResponseEntity.ok("Inscription réussie !");
    }
    @PostMapping("/login")
public ResponseEntity<?> login(@RequestBody LoginRequest request) {
    User user = userRepository.findByEmail(request.getEmail())
            .orElse(null);

    if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
        return ResponseEntity.status(401).body("Email ou mot de passe incorrect !");
    }

    String token = jwtService.generateToken(user.getEmail());

    return ResponseEntity.ok(new LoginResponse(token, user.getRole().name()));
}
}
