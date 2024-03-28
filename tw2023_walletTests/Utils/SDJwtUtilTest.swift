//
//  SDJwtUtilTest.swift
//  tw2023_walletTests
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import XCTest
@testable import tw2023_wallet

class SDJwtUtilTests: XCTestCase {
    
    // See https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-07.html#name-sd-jwt-data-formats
    let sdJwtWithoutDisclosureAndKBJ = "ISSUER_SIGNED_JWT~"
    let sdJwtWithoutDisclosureWithKBJ = "ISSUER_SIGNED_JWT~KBJ"
    let sdJwtWithDisclosureWithoutKBJ = "ISSUER_SIGNED_JWT~DISCLOSURE1~DISCLOSURE2~"
    let sdJwtWithDisclosureWithKBJ = "ISSUER_SIGNED_JWT~DISCLOSURE1~DISCLOSURE2~KBJ"
    
    let sdJwtWithDisclosureWithoutKBJ_instance = "eyJ0eXAiOiJzZCtqd3QiLCJhbGciOiJFUzI1NksiLCJ4NWMiOlsiTUlJQzFqQ0NBYjZnQXdJQkFnSVVXd3ZhU1RyMjgxV3o1R0wrQjNsK1ZONW1YWm93RFFZSktvWklodmNOQVFFTEJRQXdKVEVqTUNFR0ExVUVBd3dhVkdWemRDQkRaWEowYVdacFkyRjBaU0JCZFhSb2IzSnBkSGt3SGhjTk1qTXhNVEE1TURFMU5UTXpXaGNOTWpReE1UQTRNREUxTlRNeldqQnFNUXN3Q1FZRFZRUUdFd0pLVURFU01CQUdBMVVFQ0F3SjVwMng1THFzNllPOU1SSXdFQVlEVlFRSERBbm1sckRscnIvbGpMb3hIVEFiQmdOVkJBb01GT2FncXVXOGorUzhtdWVrdmtSaGRHRlRhV2R1TVJRd0VnWURWUVFEREF0a1lYUmhjMmxuYmk1cWNEQldNQkFHQnlxR1NNNDlBZ0VHQlN1QkJBQUtBMElBQk0yNW53b21QdlZ1dkdzOGdnZVU2dnUzMmQrK0I3eWJ5MWI1R0JUbkcraFJxd1hnL0xZTFg0RldzQ0htZXFHZzFVZzA1MEhOTHM5WVBqMkdaVEprWVFLamdZWXdnWU13RmdZRFZSMFJCQTh3RFlJTFpHRjBZWE5wWjI0dWFuQXdIUVlEVlIwT0JCWUVGRVVTZUpNOEtTcXg1M0c0ZVUxQjQvMW5qQUhZTUVvR0ExVWRJd1JETUVHaEthUW5NQ1V4SXpBaEJnTlZCQU1NR2xSbGMzUWdRMlZ5ZEdsbWFXTmhkR1VnUVhWMGFHOXlhWFI1Z2hRdHdBL3hzMmxxbzFTRUJXTlhtbWVFaGJqdXF6QU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFIZFIzdXV0b0MrUlE3NTBNY0x6OWVGdHpFcnVZa0dVMGFDbkNNenBNSjNITVc2M3BPS0ZWVmhwTnhpcnorcG0vRnBEd0FjTFQxamdLdmRiSDRjYWk4b1RmZDg0R3VFbGR4T3lOWVZySXlia0pPSmxhMXRabG9XNldqR2ZLVlk4WUFhS3dIVlFCY3dhL3N0ZDE4ajNnN0NBL2g5VjR3S1V0UFlMS05vYkFPay9DU0QyQkNIU2R0NDlNUmRrZ3lpZ2p4aDY1NHFrL0RJc3JLejZWVVI3L1VQdnVHdXdQdFpoaElzLzg5T29OWjJ5dk1LQ2ZmTUdITEw5VEtlR0dWVmY5b3pWeFYvbE5ibmVYbUdEMmt2WjF6RmJSd2FZQ213NERjSUFZTGlqMjluYWhib1k4MGhkdDg2SFplNDJlc1FTQkRCemFUeUE0RXZYSDVsNUFVdFNIbWc9PSIsIk1JSUMwVENDQWJrQ0ZDM0FEL0d6YVdxalZJUUZZMWVhWjRTRnVPNnJNQTBHQ1NxR1NJYjNEUUVCQ3dVQU1DVXhJekFoQmdOVkJBTU1HbFJsYzNRZ1EyVnlkR2xtYVdOaGRHVWdRWFYwYUc5eWFYUjVNQjRYRFRJek1URXdPVEF4TkRrME5Wb1hEVEkwTVRFd09EQXhORGswTlZvd0pURWpNQ0VHQTFVRUF3d2FWR1Z6ZENCRFpYSjBhV1pwWTJGMFpTQkJkWFJvYjNKcGRIa3dnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEQ2oyZzFtN1lRWmIxTE1PbE15MnpyT0NnOWNBRXpySzdyY3R5bUZGZDlyNzdKTU9pMWMzbnpJbTZaV2Vtd1NOeEdZMnlVU0IrQ05ISkRRK1c5dk8yTS85RkZ2dUt4TWZWQ0RERUJWMXc5cmtOZGpJR2N2aExBNlZqaHhvQU4wWDRWUm04cHpXN0tLc3I5UE1yMkhaVmJxb3JMVG5Ua0M1YUhob3FWY0xlL09Gbm00TnpVMDJCOXhlY2Fhb3FhalBBWEhsdEZ0RCtEVktFNm1RdVJ0RDhLT0lSaFBmSDlVdW9yT1lWMmVtTEt3MWI3TUZNNU84SUVUY0tEMnRhemNIUlFiRmlvLzZWU1lYaWtCekhJOWJ0dGZkMnFtbVRtVE9MSWhGc2dUYm5acWxHYzltWWIzSEEybVN5blhnMC9OemRPNE1zRi9iaEZtd1N2Q3hCUENZbVJBZ01CQUFFd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFMekhCZXZPeGJWWEhEOGlIZGhqTHFiVURpWmtPTzg0VU5JRk9JY2VxNEo2ODVxeEphSlo2NVNKVjZmM2d3YlJhM0JDZUpzTEdTa3RjS0o1a2NOOFMzc0ZBQm1Nb1lTQm4vS0xHMjY3Mm9PQ21kYVpWL25vdHVoeDJwd3FyVHROLzVadzE0VWxBNzhiSDhzdUN6SEtwZFNiR1I3clpRbVh5QWtJbDJWVUdPRkNrbFdLeWxzWEZZY29UL2p3Z2dUbGYyNnp3Ynpsa2pJRkZZK3NYcjBuOGdDYWw5bzQwZUhhTldBc2tOZEEyQ3ZpcXg1RklsdG83L09LMGxyS2lKeGtOSThFY0JCUVJlMG1EbnpqNlFYeFlMT3FpaEMxb3dRdWtVY05GSGR5YTRsdlZYMWYxaHgyUkRMWUcycWd2WmVQemY2R3lSSDBtVVM5YXNwNmNCUjhBc2M9Il19.eyJjbmYiOnsia3R5IjoiRUMiLCJjcnYiOiJzZWNwMjU2azEiLCJ4IjoidFZ3VHBCRTB2QVlpdnZXOGlseWtnYWQ4RFM3cHFVcUNiUU9JQ2gwU29nbyIsInkiOiJTalZIbS1QX0NrWUVteURDR2p5OUlWc3Rsb0YyVDB3cUZVREtMeUVER1J3In0sImlhdCI6MCwidHlwZSI6IiIsImlzcyI6IiIsIl9zZCI6WyIySTdTcFVQcE11R1VlMjVDM21wN0ExRG10R1NiQnBnN0Qwb2dRbHI0VWZFIiwicmdyVW42M0ZhblJkTGlqc3pPUEkyN0FOUHA0NnVpV2kxRFdYX3k0VlRqWSIsIndpT2ZDdTUwYmpURldoZkktWGJmNGFlR19WSi0zOWdYV3BXQV9ILVdEUG8iLCIwSFdCUEZmVTFJSjhZYXFsUGdJeEJHQ3QtNlUtTjJJRWw3X1JzMTY5OGdFIiwiOEI1M1BENzdHMkMyajFnd180V0o4a1pTalY3S0I5MjNodVhpMVBWeGpmYyIsIlN2VXdfSFh5cVNqcUxLTHN6dG5GcHlEMkRwb1JsczYybG44SzVMcFUxS0EiLCJfU0lKLUtqTWxzaGtnbkFtYmVxM0pPenduVGhNU0hzZ08wTW1BQXJadHBnIl19.dNzrFlXB98jAUxzMxWG6hgbXb59fsX_Ib0tpYOOh_6d4qsxYIfh8_VkcrcSZmCmVr-p8tjXk_PfEdM25XgP9fA~WyJjRXdQVDU2NmNpSVhMb1VUIiwidmVyaWZpZWRfYXQiLDBd~WyJteE0xRjdOQzBmY1hDdERnIiwibGFzdF9uYW1lIiwiIl0~WyJXYmRLbTVEMzYwZVNNczltIiwiZmlyc3RfbmFtZSIsIiJd~WyJuR05ldXRwTjY4UEFRdGVvIiwiaXNfb3JkZXJfdGhhbl8xNSIsZmFsc2Vd~WyJ0TGljVHJwdWh2c2ZrMmlSIiwiaXNfb3JkZXJfdGhhbl8xOCIsZmFsc2Vd~WyJjYmFBSGY4eUl6RXFack8xIiwiaXNfb3JkZXJfdGhhbl8yMCIsZmFsc2Vd~WyJhUEpQcHhTb2dIMkpKYUhMIiwiaXNfb3JkZXJfdGhhbl82NSIsZmFsc2Vd~"
    
    
    func testDevideSDJwtSignedJwtExtraction() {
        do {
            let parts1 = try SDJwtUtil.divideSDJwt(sdJwtWithoutDisclosureAndKBJ)
            let parts2 = try SDJwtUtil.divideSDJwt(sdJwtWithoutDisclosureWithKBJ)
            let parts3 = try SDJwtUtil.divideSDJwt(sdJwtWithDisclosureWithoutKBJ)
            let parts4 = try SDJwtUtil.divideSDJwt(sdJwtWithDisclosureWithKBJ)
            
            // Issuer Signed Jwt
            XCTAssertEqual("ISSUER_SIGNED_JWT", parts1.issuerSignedJwt)
            XCTAssertEqual("ISSUER_SIGNED_JWT", parts2.issuerSignedJwt)
            XCTAssertEqual("ISSUER_SIGNED_JWT", parts3.issuerSignedJwt)
            XCTAssertEqual("ISSUER_SIGNED_JWT", parts4.issuerSignedJwt)
            
            // Disclosure
            XCTAssertTrue(parts1.disclosures.isEmpty)
            XCTAssertTrue(parts2.disclosures.isEmpty)
            XCTAssertTrue(parts3.disclosures.count == 2)
            XCTAssertTrue(parts4.disclosures.count == 2)
            
            // KBJWT
            XCTAssertNil(parts1.keyBindingJwt)
            XCTAssertNil(parts3.keyBindingJwt)
            XCTAssertNotNil(parts2.keyBindingJwt)
            XCTAssertNotNil(parts4.keyBindingJwt)
        }catch{
            XCTFail("An error occurred: \(error)")
        }
    }
    
    func testDecodeDisclosure(){
        do {
            let parts = try SDJwtUtil.divideSDJwt(sdJwtWithDisclosureWithoutKBJ_instance)
            let expected: [String] = ["verified_at", "last_name", "first_name", "is_order_than_15", "is_order_than_18", "is_order_than_20", "is_order_than_65"]
            
            let decodedDisclosures = SDJwtUtil.decodeDisclosure(parts.disclosures)
            
            for disclosure in decodedDisclosures {
                if let keyName = disclosure.key {
                    XCTAssertTrue(expected.contains(keyName), "Key '\(keyName)' not found in the expected set")
                }
            }
        }catch{
            XCTFail("An error occurred: \(error)")
        }
    }
    
    func testgetDecodedJwtHeader() {
        guard let headerJSON = SDJwtUtil.getDecodedJwtHeader(sdJwtWithDisclosureWithoutKBJ_instance) else {
            XCTFail("Failed to decode JWT header")
            return
        }
        XCTAssertTrue(headerJSON.keys.contains("alg"), "JSON does not contain 'alg'")
        XCTAssertTrue(headerJSON.keys.contains("x5c"), "JSON does not contain 'x5c'")
    }
}
