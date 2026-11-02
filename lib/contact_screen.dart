import 'package:flutter/material.dart';
import 'database_helper.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllContacts(
      searchQuery: _searchController.text.trim(),
      favoritesOnly: _showFavoritesOnly,
    );
    setState(() {
      _contacts = data;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(Contact contact) async {
    final updated = contact.copyWith(isFavorite: !contact.isFavorite);
    await DatabaseHelper.instance.updateContact(updated);
    _refreshContacts();
  }

  Future<void> _deleteContact(int id) async {
    await DatabaseHelper.instance.deleteContact(id);
    _refreshContacts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact deleted')),
      );
    }
  }

  void _openContactForm([Contact? contact]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContactFormDialog(
        contact: contact,
        onSave: () => _refreshContacts(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? Colors.redAccent : null,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
              _refreshContacts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshContacts();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _refreshContacts(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                ? Center(
              child: Text(
                _showFavoritesOnly
                    ? 'No favorite contacts found.'
                    : 'No contacts available.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final item = _contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.phone,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              if (item.email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.email,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                              if (item.address.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.address,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                item.isFavorite ? Icons.star : Icons.star_border,
                                color: item.isFavorite ? Colors.red : Colors.grey,
                                size: 22,
                              ),
                              onPressed: () => _toggleFavorite(item),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _openContactForm(item),
                                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _deleteContact(item.id!),
                                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openContactForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }
}

class ContactFormDialog extends StatefulWidget {
  final Contact? contact;
  final VoidCallback onSave;

  const ContactFormDialog({super.key, this.contact, required this.onSave});

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  late String _email;
  late String _address;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _phone = widget.contact?.phone ?? '';
    _email = widget.contact?.email ?? '';
    _address = widget.contact?.address ?? '';
    _isFavorite = widget.contact?.isFavorite ?? false;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newContact = Contact(
        id: widget.contact?.id,
        name: _name,
        phone: _phone,
        email: _email,
        address: _address,
        isFavorite: _isFavorite,
      );

      if (widget.contact == null) {
        await DatabaseHelper.instance.insertContact(newContact);
      } else {
        await DatabaseHelper.instance.updateContact(newContact);
      }

      widget.onSave();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: bottomPadding + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.contact == null ? 'Add New Contact' : 'Edit Contact', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a name' : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a phone number' : null,
                onSaved: (val) => _phone = val!.trim(),
              ),
              const SizedBox(height: 12),
              // Email ekhon optional (validator bad dewa hoyeche)
              TextFormField(
                initialValue: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (Optional)', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                onSaved: (val) => _email = val != null ? val.trim() : '',
              ),
              const SizedBox(height: 12),
              // Address ekhon optional (validator bad dewa hoyeche)
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(labelText: 'Address (Optional)', prefixIcon: Icon(Icons.home), border: OutlineInputBorder()),
                onSaved: (val) => _address = val != null ? val.trim() : '',
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Mark as Favorite'),
                value: _isFavorite,
                onChanged: (val) => setState(() => _isFavorite = val ?? false),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: _submit,
                child: Text(widget.contact == null ? 'Save' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}