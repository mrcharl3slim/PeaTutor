import SwiftUI

struct RoleSelectionView: View {
    @Binding var selectedRole: UserRole?
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                Text("Choose Your Role")
                    .font(.title.bold())
                
                Text("Select how you'll be using MagicMaths")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Role Cards
            VStack(spacing: 16) {
                ForEach(UserRole.allRoles, id: \.self) { role in
                    RoleCard(
                        role: role,
                        isSelected: selectedRole == role,
                        onTap: { selectedRole = role }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        selectedRole != nil ? Color.blue : Color.gray
                    )
                    .cornerRadius(16)
            }
            .disabled(selectedRole == nil)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: role.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RoleSelectionView(
        selectedRole: .constant(.teacher),
        onContinue: {}
    )
}
